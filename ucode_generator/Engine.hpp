#pragma once

#define SOL_ALL_SAFETIES_ON 1
#define SOL_PRINT_ERRORS 0
#include <lua/lua.hpp>
#include <sol/sol.hpp>

#include <string>
#include <unordered_map>

class Engine {
public:
	Engine(const std::string& script_folder);

	void generate();
	void save_hex(const std::string& output_filename);

private:
	void generate_ctrl_addr();
	void generate_ctrl_sigs();

	void update_ctrl_addr();

	sol::optional<unsigned int> get_ctrl_sequence(const std::string& lua_value);
	

	template<typename T> void update_lua_table(const std::vector<std::string>& path, T value);
	template<typename T> T expect_value(const std::string& name);



	sol::state m_lua;
	std::string m_script_folder{};

	std::unordered_map<std::string, bool> m_ctrl_addr{};
	sol::optional<unsigned int> m_start_cycle{ sol::nullopt }, m_fetch_cycle{ sol::nullopt }, m_phase_inc{ sol::nullopt };
};

#include "Engine.inl"