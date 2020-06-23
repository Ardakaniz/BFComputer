template<typename T>
void Engine::UpdateLuaTable(const std::vector<std::string>& path, T value) {
	sol::optional<sol::table> table = sol::nullopt;
	for (auto it = std::begin(path); it != std::end(path) - 1; ++it) {
		if (table.has_value())
			table = (*table)[*it].get_or_create<sol::table>(sol::new_table());
		else
			table = _lua[*it].get_or_create<sol::table>(sol::new_table());
	}

	if (table.has_value())
		(*table)[path.back()] = value;
	else
		_lua[path.back()] = value;
}

inline unsigned int Engine::MsbPos(unsigned int num) const {
	return static_cast<unsigned int>(std::floor(std::log2(num)) + 1);
}