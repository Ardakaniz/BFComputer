#pragma once

#define SOL_ALL_SAFETIES_ON 1
#define SOL_PRINT_ERRORS 0
#include <lua/lua.hpp>
#include <sol/sol.hpp>

#include <unordered_map>

class Engine {
public:
	Engine(const std::string& script_file);

	void Generate();
	void SaveHex();
	void SaveTxt();

private:
	template<typename T> void UpdateLuaTable(const std::vector<std::string>& path, T value);
	inline unsigned int MsbPos(unsigned int val) const;

	std::string _script_file;
	sol::state _lua;

	std::size_t _addr_count{ 0 };
	std::size_t _cs_count{ 0 };
	unsigned int _addr_mask{ 0 };
	unsigned int _neg_addr_mask{ 0 };
	unsigned int _active_low_cs{};
	std::vector<unsigned int> _rom{};
};

#include "Engine.inl"