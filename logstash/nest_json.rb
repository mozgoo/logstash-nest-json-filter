require 'json'

def register(params)
  @max_nest = params["max_nest"]
  @source = params["source"]
  @target = params["target"]
end

def parseHash(hash, nest_count=1)
  hash.each do |key, value|
    if value.is_a?(Hash) 
      if (nest_count < @max_nest) and (not value.kind_of?(Array))
        parseHash(value, nest_count+1)
      else
        hash[key] = JSON.generate(value)
      end
    end
  end
end

def filter(event)
  source = event.get(@source)
  begin
    full_parsed = JSON.parse(source)
    rescue => e
      @logger.warn("Error parsing json", :source => @source, :raw => source, :exception => e)
      event.tag("error_parsed_full_hash")
      return [event]
  end

  begin
    parsed = parseHash(full_parsed)
  rescue => e
      @logger.warn("Error parsing json", :source => @source, :raw => source, :exception => e)
      event.tag("error_parsed_nest_hash")
      return [event]
  end

  if @target
    event.set(@target, parsed)
    return [event]
  else
    unless parsed.is_a?(Hash)
      @logger.warn("Parsed JSON object/hash requires a target configuration option", :source => @source, :raw => source)
      event.tag("parsed_obj_is_not_hash")
      return [event]
    end
  end
end