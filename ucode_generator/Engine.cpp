#include "Engine.hpp"
#include "StringSplit.hpp"

#include <fstream>
#include <vector>

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
	

	m_lua.set_function("is_opcode", [this](const std::string& instr) {
		auto it = std::find(std::begin(m_instructions), std::end(m_instructions), instr);

		if (it == std::end(m_instructions))
			throw std::runtime_error{ "Invalid instruction: " + instr };

		const unsigned int opcode = std::distance(std::begin(m_instructions), it);
		const unsigned int opcode_mask = static_cast<unsigned int>(std::pow(2, num_bits(m_ctrl_addr_count.opcode))) - 1;
		return ((m_rom_index & opcode_mask) == opcode);
	});

}

void Engine::generate() {
	bool do_fetch{ false };
	m_lua.set_function("exec", [&do_fetch, this](const sol::table& cs) { lua_exec(do_fetch, true, true, true, cs); });
	m_lua.set_function("exec_no_start", [&do_fetch, this](const sol::table& cs) { lua_exec(do_fetch, false, true, true, cs); });
	m_lua.set_function("exec_no_fetch", [&do_fetch, this](const sol::table& cs) { lua_exec(do_fetch, true, false, true, cs); });
	m_lua.set_function("exec_no_phase", [&do_fetch, this](const sol::table& cs) { lua_exec(do_fetch, true, true, false, cs); });

	sol::load_result script = m_lua.load_file(m_script_folder + "/script.lua");

	for (m_rom_index = 0; m_rom_index < m_ucode_rom.size(); ++m_rom_index) {
		update_ctrl_addr();

		m_phase = 0;
		if (auto result = script(); !result.valid())
			sol::script_throw_on_error(m_lua.lua_state(), result);

		if (do_fetch)
			m_ucode_rom[m_rom_index] |= m_fetch_cycle;
	}
}

void Engine::save_hex() {
	std::ofstream hex;
	for (unsigned int cs_idx{ 0 }; cs_idx < static_cast<unsigned int>(std::ceil(m_ctrl_sigs_count / 8.)); ++cs_idx) {
		const std::string filename{ "out" + std::to_string(cs_idx * 8) + "-" + std::to_string(cs_idx * 8 + 7) + ".hex" };

		hex.open(filename, std::ios::binary);
		if (!hex.is_open())
			throw std::runtime_error{ "Failed to create hex file: " + filename };

		for (auto ucode_word : m_ucode_rom) {
			hex.put(static_cast<char>((ucode_word >> (cs_idx * 8)) & 0xff));
		}		
		hex.close();
	}
}

void Engine::generate_ctrl_addr() {
	const auto flags = expect_value<std::vector<std::string>>("flags");
	m_ctrl_addr_count.phase = expect_value<unsigned int>("phase_count");
	m_instructions = expect_value<std::vector<std::string>>("instructions");
	m_ctrl_addr_count.opcode = m_instructions.size();

	const auto ctrl_addr_org = expect_value<std::vector<unsigned int>>("ctrl_addr_org");

	std::vector<unsigned int> already_found{};
	m_ctrl_addr_pos.phase = 0;
	bool phase_found{ false }, opcode_found{ false };
	for (auto i : ctrl_addr_org) {
		if (std::find(std::begin(already_found), std::end(already_found), i) != std::end(already_found)) {
			throw std::runtime_error{ "[setup.lua] Invalid control adress organization: cannot have multiple time the same flag" };
		}

		switch (i) {
		case 0: // FLAGS
			for (const auto& flag : flags) {
				m_ctrl_addr_names.emplace_back(flag);
			}

			if (!phase_found)
				m_ctrl_addr_pos.phase += static_cast<unsigned int>(flags.size());
			if (!opcode_found)
				m_ctrl_addr_pos.opcode += static_cast<unsigned int>(flags.size());
			break;

		case 1: // PHASE
			for (unsigned int phase{ 0 }; phase < num_bits(m_ctrl_addr_count.phase); ++phase) {
				m_ctrl_addr_names.emplace_back("p" + std::to_string(phase));
			}

			phase_found = true;
			break;

		case 2: // OPCODE
		{
			const unsigned int opcode_bits = num_bits(m_instructions.size());
			for (unsigned int opcode{ 0 }; opcode < opcode_bits; ++opcode) {
				m_ctrl_addr_names.emplace_back("op" + std::to_string(opcode));
			}

			if (!phase_found)
				m_ctrl_addr_pos.phase += opcode_bits;
			if (!opcode_found)
				m_ctrl_addr_pos.opcode += opcode_bits;

			opcode_found = true;
			break;
		}

		default:
			throw std::runtime_error{ "[setup.lua] Invalid control adress organization flag" };
		}

		already_found.push_back(i);
	}

	if (already_found.size() != 3)
		throw std::runtime_error{ "[setup.lua] Invalid control adress organization: FLAGS, PHASE or OPCODE is missing" };

	// Because lsb first in Lua code
	m_ctrl_addr_pos.phase = static_cast<unsigned int>(m_ctrl_addr_names.size()) - m_ctrl_addr_pos.phase - num_bits(m_ctrl_addr_count.phase);
	m_ctrl_addr_pos.opcode = static_cast<unsigned int>(m_ctrl_addr_names.size()) - m_ctrl_addr_pos.opcode - num_bits(m_ctrl_addr_count.opcode);

	m_ucode_rom.resize(static_cast<std::size_t>(std::pow(2, m_ctrl_addr_names.size())), false);
}

void Engine::generate_ctrl_sigs() {
	const auto ctrl_sigs = expect_value<std::vector<std::string>>("ctrl_sigs");
	m_ctrl_sigs_count = static_cast<unsigned int>(ctrl_sigs.size());

	for (unsigned int i{ 0 }; i < m_ctrl_sigs_count; ++i) {
		update_lua_table(string_split<'.'>(ctrl_sigs[i]), static_cast<unsigned int>(std::pow(2, i)));
	}

	m_start_cycle = get_ctrl_sequence("start_cycle");
	m_fetch_cycle = get_ctrl_sequence("fetch_cycle");
	m_phase_inc   = get_ctrl_sequence("phase_inc");
}

void Engine::update_ctrl_addr() {
	for (unsigned int i{ 0 }; i < m_ctrl_addr_names.size(); ++i) {
		m_lua[m_ctrl_addr_names[i]] = static_cast<bool>((m_rom_index >> (m_ctrl_addr_names.size() - i - 1)) & 1);
	}
}

unsigned int Engine::get_ctrl_sequence(const std::string& lua_value) {
	unsigned int ctrl_sequence = 0;

	const sol::optional<std::vector<std::string>> sequence_str = m_lua[lua_value];
	if (sequence_str.has_value()) {
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

			ctrl_sequence |= *cs_int;
		}
	}

	return ctrl_sequence;
}

void Engine::lua_exec(bool& do_fetch, bool start_cycle, bool fetch_cycle, bool phase_inc, const sol::table& cs) {
	if (m_phase >= m_ctrl_addr_count.phase)
		throw std::runtime_error{ "Too many exec instruction: phase count is " + std::to_string(m_ctrl_addr_count.phase) };

	const unsigned int phase_mask = (static_cast<unsigned int>(std::pow(2, num_bits(m_ctrl_addr_count.phase))) - 1);
	if (((m_rom_index >> m_ctrl_addr_pos.phase) & phase_mask) != m_phase) { // Not the right phase, we don't exec anything
		do_fetch = false;
		if (phase_inc)
			++m_phase;

		return;
	}
	
	unsigned int final_cs = 0;
	for (auto i : cs) {
		if (i.second.get_type() != sol::type::number)
			throw std::runtime_error{ "[script.lua] exec(): Invalid arguments, expected control signal flag" };

		final_cs |= i.second.as<unsigned int>();
	}

	if (start_cycle && m_phase == 0)
		final_cs |= m_start_cycle;
	if (phase_inc) {
		final_cs |= m_phase_inc;
		++m_phase;
	}

	m_ucode_rom[m_rom_index] = final_cs;

	do_fetch = fetch_cycle;
}

unsigned int Engine::num_bits(unsigned int num) {
	return static_cast<unsigned int>(std::ceil(std::log2(num)));
}