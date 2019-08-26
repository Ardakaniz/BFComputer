#include "Engine.hpp"
#include "StringSplit.hpp"

#include <vector>
#include <iostream>

Engine::Engine(const std::string& script_folder) :
	m_script_folder{ script_folder }
{
	m_lua.open_libraries();

	m_lua.set("FLAGS", 0);
	m_lua.set("PHASE", 1);
	m_lua.set("OPCODE", 2);

	m_lua.script_file(m_script_folder + "/setup.lua");

	m_lua.set("FLAGS", sol::lua_nil);
	m_lua.set("PHASE", sol::lua_nil);
	m_lua.set("OPCODE", sol::lua_nil);

	generate_ctrl_addr();
	generate_ctrl_sigs();
	

	m_lua.set_function("is_opcode", [](const std::string& opcode) {
		return true;
	});

	m_lua.set_function("exec", [](const sol::table& cs) {
		unsigned int final_cs = 0;
		for (auto i : cs) {
			if (i.second.get_type() != sol::type::number)
				throw std::runtime_error{ "[script.lua] exec(): Invalid arguments, expected control signal flag" };

			final_cs |= i.second.as<unsigned int>();
		}

		std::cout << final_cs << std::endl;
	});
}

void Engine::generate() {
	m_lua.script_file(m_script_folder + "/script.lua");
}

void Engine::save_hex(const std::string& output_filename) {

}

void Engine::generate_ctrl_addr() {
	const auto flags = expect_value<std::vector<std::string>>("flags");
	const auto phase_count = expect_value<unsigned int>("phase_count");
	const auto instructions = expect_value<std::vector<std::string>>("instructions");

	const auto ctrl_addr_org = expect_value<std::vector<unsigned int>>("ctrl_addr_org");
	std::vector<unsigned int> already_found{};
	for (auto i : ctrl_addr_org) {
		if (std::find(std::begin(already_found), std::end(already_found), i) != std::end(already_found)) {
			throw std::runtime_error{ "[setup.lua] Invalid control adress organization: cannot have multiple time the same flag" };
		}

		switch (i) {
		case 0: // FLAGS
			for (const auto& flag : flags) {
				m_ctrl_addr[flag] = false;
			}
			break;

		case 1: // PHASE
			for (unsigned int phase{ 0 }; phase < static_cast<unsigned int>(std::ceil(std::log2(phase_count))); ++phase) {
				m_ctrl_addr["p" + std::to_string(phase)] = false;
			}

			break;

		case 2: // OPCODE
			for (unsigned int opcode{ 0 }; opcode < static_cast<unsigned int>(std::ceil(std::log2(instructions.size()))); ++opcode) {
				m_ctrl_addr["op" + std::to_string(opcode)] = false;
			}

			break;

		default:
			throw std::runtime_error{ "[setup.lua] Invalid control adress organization flag" };
		}

		already_found.push_back(i);
	}

	if (already_found.size() != 3)
		throw std::runtime_error{ "[setup.lua] Invalid control adress organization: FLAGS, PHASE or OPCODE is missing" };

	update_ctrl_addr();
}

void Engine::generate_ctrl_sigs() {
	const auto ctrl_sigs = expect_value<std::vector<std::string>>("ctrl_sigs");

	for (unsigned int i{ 0 }; i < ctrl_sigs.size(); ++i) {
		update_lua_table(string_split<'.'>(ctrl_sigs[i]), static_cast<unsigned int>(std::pow(2, i)));
	}

	m_start_cycle = get_ctrl_sequence("start_cycle");
	m_fetch_cycle = get_ctrl_sequence("fetch_cycle");
	m_phase_inc   = get_ctrl_sequence("phase_inc");
}

void Engine::update_ctrl_addr() {
	for (const auto& i : m_ctrl_addr) {
		m_lua[i.first] = i.second;
	}
}

sol::optional<unsigned int> Engine::get_ctrl_sequence(const std::string& lua_value) {
	sol::optional<unsigned int> ctrl_sequence = sol::nullopt;

	const sol::optional<std::vector<std::string>> sequence_str = m_lua[lua_value];
	if (sequence_str.has_value()) {
		ctrl_sequence = 0;
		for (const auto& cs : *sequence_str) {
			std::vector<std::string> table_path = string_split<'.'>(cs);
			if (table_path.empty())
				continue;

			sol::optional<unsigned int> cs_int{ sol::nullopt };
			if (table_path.size() >= 2) {
				sol::optional<sol::table> table = m_lua[table_path.front()];
				if (!table.has_value())
					throw std::runtime_error{ "[setup.lua] Invalid control signal for '" + lua_value + "': " + cs };

				for (auto it = std::begin(table_path) + 1; it != std::end(table_path) - 1; ++it) {
					sol::optional<sol::table> other_table = (*table)[*it];
					table = other_table;
					if (!table.has_value())
						throw std::runtime_error{ "[setup.lua] Invalid control signal for '" + lua_value + "': " + cs };
				}

				cs_int = (*table)[table_path.back()];
			}
			else {
				cs_int = m_lua[table_path.front()];
			}

			if (!cs_int.has_value())
				throw std::runtime_error{ "[setup.lua] Invalid control signal for '" + lua_value + "': " + cs };

			*ctrl_sequence |= *cs_int;
		}
	}

	return ctrl_sequence;
}