local sh = { }

sh.batchable = true

function sh:constructDefinesGlobal(dream)
	return [[
		uniform int point_simple_count;
		
		uniform vec3 point_simple_pos[]] .. dream.max_lights .. [[];
		uniform vec3 point_simple_color[]] .. dream.max_lights .. [[];
		uniform float point_simple_attenuation[]] .. dream.max_lights .. [[];
	]]
end

function sh:constructDefines(ID)
	
end

function sh:constructPixelGlobal(dream)
	return ([[
	for (int i = 0; i < point_simple_count; i++) {
		vec3 lightVec = point_simple_pos[i] - vertexPos;
		float distance = length(lightVec) + 1.0;
		float power = pow(distance, point_simple_attenuation[i]);
		vec3 lightColor = point_simple_color[i] * power;
		lightVec = normalize(lightVec);
		
		light += getLight(lightColor, viewVec, lightVec, normal, albedo, roughness, metallic);
	}
	]])
end

function sh:constructPixelBasicGlobal(dream)
	return ([[
	for (int i = 0; i < point_simple_count; i++) {
		vec3 lightVec = point_simple_pos[i] - vertexPos;
		float distance = length(lightVec) + 1.0;
		float power = pow(distance, point_simple_attenuation[i]);
		light += point_simple_color[i] * power;
	}
	]])
end

function sh:constructPixel(ID)

end

function sh:constructPixelBasic(ID)

end

function sh:sendGlobalUniforms(shaderObject, count, lighting)
	local shader = shaderObject.shader
	
	local colors = { }
	local pos = { }
	local attenuation = { }
	for d,s in ipairs(lighting) do
		if s.light_typ == "point_simple" then
			table.insert(colors, s.color * s.brightness)
			table.insert(pos, s.position)
			table.insert(attenuation, -s.attenuation)
		end
	end
	
	shader:send("point_simple_count", count)
	shader:send("point_simple_pos", unpack(pos))
	shader:send("point_simple_color", unpack(colors))
	shader:send("point_simple_attenuation", unpack(attenuation))
end

function sh:sendUniforms(shaderObject, light, ID)
	
end

return sh