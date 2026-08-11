-- 万能五笔 v0.5：通用静态联想之上的本地个人二元学习层。

local M = {}

local candidate_property = "personal_predict_candidates"
local db_pool = {}

local function get_db(name)
  local db = db_pool[name]
  if db then
    return db
  end
  db = LevelDb(name)
  if not db or (not db:loaded() and not db:open()) then
    return nil
  end
  db_pool[name] = db
  return db
end

local function valid_text(text)
  if not text or text == "" or #text > 96 then
    return false
  end
  if text:find("[%c%s]") or not text:find("[\128-\255]") then
    return false
  end
  return true
end

local ignored_types = {
  punct = true,
  raw = true,
  thru = true,
}

local paste_keys = {
  ["Control+v"] = true,
  ["Control+V"] = true,
  ["Super+v"] = true,
  ["Super+V"] = true,
  ["Command+v"] = true,
  ["Command+V"] = true,
  ["Meta+v"] = true,
  ["Meta+V"] = true,
}

local function pair_key(previous, current)
  return "p\t" .. previous .. "\t" .. current
end

local function pair_prefix(previous)
  return "p\t" .. previous .. "\t"
end

local function parse_value(value)
  if not value then
    return 0, 0
  end
  local count, timestamp = value:match("^(%d+)\t(%d+)$")
  return tonumber(count) or 0, tonumber(timestamp) or 0
end

local function learn_pair(env, previous, current)
  if not env.db or previous == current then
    return
  end
  local key = pair_key(previous, current)
  local count = parse_value(env.db:fetch(key))
  env.db:update(key, tostring(count + 1) .. "\t" .. tostring(os.time()))
end

local function query_candidates(env, previous)
  if not env.db then
    return {}
  end
  local prefix = pair_prefix(previous)
  local now = os.time()
  local candidates = {}
  local accessor = env.db:query(prefix)
  if not accessor then
    return candidates
  end
  for key, value in accessor:iter() do
    if key:sub(1, #prefix) ~= prefix then
      break
    end
    local text = key:sub(#prefix + 1)
    local count, timestamp = parse_value(value)
    if count >= env.min_count and valid_text(text) then
      local age_days = math.max(0, now - timestamp) / 86400
      local recency = math.max(0, 1 - age_days / 30) * 0.5
      table.insert(candidates, {
        text = text,
        count = count,
        timestamp = timestamp,
        score = math.log(1 + count) + recency,
      })
    end
  end
  table.sort(candidates, function(a, b)
    if a.score ~= b.score then
      return a.score > b.score
    end
    if a.timestamp ~= b.timestamp then
      return a.timestamp > b.timestamp
    end
    return a.text < b.text
  end)
  while #candidates > env.max_candidates do
    table.remove(candidates)
  end
  return candidates
end

local function encode_candidates(candidates)
  local rows = {}
  for _, item in ipairs(candidates) do
    table.insert(rows, item.text .. "\t" .. tostring(item.count))
  end
  return table.concat(rows, "\n")
end

local function on_commit(ctx, env)
  local record = ctx.commit_history:back()
  if not record or ignored_types[record.type] or not valid_text(record.text) then
    env.previous = nil
    env.pending = nil
    env.stop_after_prediction = false
    return
  end

  local current = record.text
  if ctx:get_option("personal_learning") and env.previous then
    learn_pair(env, env.previous, current)
  end

  env.previous = current
  env.pending = current
  env.stop_after_prediction =
    record.type == "personal_prediction" or record.type == env.candidate_type
end

local function on_update(ctx, env)
  if env.composing_prediction or not env.pending then
    return
  end

  local previous = env.pending
  env.pending = nil
  if env.stop_after_prediction then
    env.stop_after_prediction = false
    return
  end
  if not ctx:get_option(env.prediction_option) then
    return
  end

  local candidates = query_candidates(env, previous)

  -- 通用 predictor 已经创建联想段时，把个人候选挂到同一个段上。
  -- 这样个人候选以更高 quality 排在通用候选之前，后续 uniquifier 负责去重。
  local existing = ctx.composition:back()
  if existing and existing:has_tag("prediction") then
    if #candidates > 0 then
      ctx:set_property(candidate_property, encode_candidates(candidates))
      existing.tags = Set({"prediction", "personal_prediction", "placeholder"})
    end
    return
  end

  -- 通用库没有当前前词时，个人数据库仍可独立产生联想。
  if ctx:is_composing() or #candidates == 0 then
    return
  end

  ctx:set_property(candidate_property, encode_candidates(candidates))
  local position = #ctx.input
  local segment = Segment(position, position)
  segment.tags = Set({"personal_prediction", "placeholder"})
  ctx.composition:push_back(segment)

  env.composing_prediction = true
  env.engine:compose(ctx)
  env.composing_prediction = false
end

M.processor = {}

function M.processor.init(env)
  local config = env.engine.schema.config
  local db_name = config:get_string("personal_predictor/db") or "personal_predict"
  env.prediction_option =
    config:get_string("personal_predictor/prediction_option") or "personal_prediction"
  env.candidate_type =
    config:get_string("personal_predictor/candidate_type") or "personal_prediction"
  env.min_count = config:get_int("personal_predictor/min_count") or 2
  env.max_candidates = config:get_int("personal_predictor/max_candidates") or 7
  env.db = get_db(db_name)
  -- luna_pinyin 同时含简繁词条；所有候选先统一为简体，再由 zh_trad 按需转繁体。
  env.engine.context:set_option("input_simplification", true)
  env.commit_connection = env.engine.context.commit_notifier:connect(
    function(ctx) on_commit(ctx, env) end
  )
  env.update_connection = env.engine.context.update_notifier:connect(
    function(ctx) on_update(ctx, env) end
  )
end

function M.processor.fini(env)
  if env.commit_connection then
    env.commit_connection:disconnect()
  end
  if env.update_connection then
    env.update_connection:disconnect()
  end
end

function M.processor.func(key, env)
  local context = env.engine.context
  local segment = context.composition:back()
  local repr = key:repr()

  if paste_keys[repr] then
    -- 粘贴不是输入法上屏：关闭本次预测、清掉残留联想，并切断学习上下文。
    -- prediction 在下一次普通按键到来时恢复，确保 native predictor 不会响应粘贴更新。
    env.restore_prediction_after_paste = context:get_option(env.prediction_option)
    if env.restore_prediction_after_paste then
      context:set_option(env.prediction_option, false)
    end
    env.previous = nil
    env.pending = nil
    env.stop_after_prediction = false
    if segment and
      (segment:has_tag("prediction") or segment:has_tag("personal_prediction")) then
      context:clear()
    end
    return 2
  end

  if env.restore_prediction_after_paste ~= nil then
    if env.restore_prediction_after_paste then
      context:set_option(env.prediction_option, true)
    end
    env.restore_prediction_after_paste = nil
  end

  if segment and segment:has_tag("personal_prediction") then
    if repr == "BackSpace" or repr == "Escape" then
      context:clear()
      return 1
    end
  end
  return 2
end

M.translator = {}

function M.translator.func(_, segment, env)
  if not segment:has_tag("personal_prediction") then
    return
  end
  local encoded = env.engine.context:get_property(candidate_property)
  for row in encoded:gmatch("[^\n]+") do
    local text, count = row:match("^([^\t]+)\t(%d+)$")
    if text then
      local candidate = Candidate(
        env.candidate_type, segment.start, segment._end, text, ""
      )
      candidate.quality = 1000 + tonumber(count)
      yield(candidate)
    end
  end
end

return M
