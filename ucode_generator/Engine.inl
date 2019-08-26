template<typename T>
void Engine::update_lua_table(const std::vector<std::string>& path, T value) {
	sol::optional<sol::table> table = sol::nullopt;
	for (auto it = std::begin(path); it != std::end(path) - 1; ++it) {
		if (table.has_value())
			table = (*table)[*it].get_or_create<sol::table>(sol::new_table());
		else
			table = m_lua[*it].get_or_create<sol::table>(sol::new_table());
	}

	if (table.has_value())
		(*table)[path.back()] = value;
	else
		m_lua[path.back()] = value;
}

template<typename T>
T Engine::expect_value(const std::string& name) {
	sol::optional<T> value = m_lua[name];
	if (!value.has_value()) {
		throw std::runtime_error{ "Expected '" + name + "' value in setup script" };
	}

	return *value;
}