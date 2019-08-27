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

	unsigned int get_ctrl_sequence(const std::string& lua_value);

	void lua_exec(bool& is_start, bool& do_fetch, bool start_cycle, bool fetch_cycle, bool phase_inc, const sol::table& cs);
	
	template<typename T> void update_lua_table(const std::vector<std::string>& path, T value);
	template<typename T> T expect_value(const std::string& name);

	unsigned int m_ctrl_sigs_count{ 0 };
	unsigned int m_phase{ 0 }, m_phase_count{ 0 }, m_phase_pos{ 0 };
	unsigned int m_rom_index{ 0 };
	unsigned int m_start_cycle{ 0 }, m_fetch_cycle{ 0 }, m_phase_inc{ 0 };
	sol::state m_lua;
	std::string m_script_folder{};
	std::unordered_map<std::string, bool> m_ctrl_addr{};
	std::vector<unsigned int> m_ucode_rom{};
};

#include "Engine.inl"