#include "Engine.hpp"

#include "StringSplit.hpp"
#include <fstream>

#include <iostream>

Engine::Engine(const std::string& script_file) :
	_script_file{ script_file }
{
	_lua.open_libraries(sol::lib::base);

	_lua.set_function("AddressNames", [&](const sol::table& addrs) {
		if (_addr_count != 0)
			throw std::runtime_error{ "AddressNames() can be called only once" };

		_addr_count = addrs.size();
		for (std::size_t i{ 0 }; i < _addr_count; ++i) {
			if (addrs[i + 1].get_type() != sol::type::string)
				throw std::runtime_error{ "AddressNames(): Invalid arguments, expected array of strings" };

			auto addr = addrs[i + 1].get<std::string>();
			_lua[addr] = static_cast<unsigned int>(std::pow(2, _addr_count - i - 1));
			_lua["n_" + addr] = static_cast<unsigned int>(std::pow(2, (2 * _addr_count) - i - 1)); // On donne des valeurs spéciales pour spécifier les adresses dont on veut qu'elles restent nulles.
		}

		_rom.resize(static_cast<std::size_t>(std::pow(2, _addr_count)), 0);
	});

	_lua.set_function("ControlSigs", [&](const sol::table& css) {
		if (_cs_count != 0)
			throw std::runtime_error{ "ControlSigs() can be called only once" };

		_cs_count = css.size();
		
		for (std::size_t i{ 0 }; i < _cs_count; ++i) {
			if (css[i + 1].get_type() != sol::type::string)
				throw std::runtime_error{ "ControlSigs(): Invalid arguments, expected array of strings" };

			auto cs = css[i + 1].get<std::string>();
			if (cs[0] == '~') {
				cs = cs.substr(1);
				_active_low_cs |= static_cast<unsigned int>(std::pow(2, i));
			}
			
			UpdateLuaTable(StringSplit<'.'>(cs), static_cast<unsigned int>(std::pow(2, i)));
		}
	});

	_lua.set_function("InitRom", [&]() {
		for (unsigned int& cell : _rom)
			cell = _active_low_cs;
	});

	_lua.set_function("Gen", [&](const sol::table& addrs, const sol::object& css) {
		const unsigned int addr_mask_backup = _addr_mask;
		const unsigned int neg_addr_mask_backup = _neg_addr_mask;

		for (const auto& addr : addrs) {
			if (addr.second.get_type() != sol::type::number)
				throw std::runtime_error{ "Gen(): Invalid arguments, expected address label" };

			unsigned int addr_val{ addr.second.as<unsigned int>() };
			unsigned int negate_val{ addr_val >> _addr_count };
			
			if (negate_val != 0) { // Si jamais ce masque est un masque pour la négation d'une adresse
				if ((negate_val & _addr_mask) != 0)
					throw std::runtime_error{ "Gen(): Can't select and deselect same address label" };

				_neg_addr_mask |= negate_val;
			}
			else {
				if ((addr_val & _neg_addr_mask) != 0)
					throw std::runtime_error{ "Gen(): Can't select and deselect same address label" };

				_addr_mask |= addr_val;
			}
		}

		if (css.get_type() == sol::type::function) {
			css.as<sol::function>()();
		}
		else if (css.get_type() == sol::type::table) {
			const unsigned int mask{ _addr_mask };
			const unsigned int browsing_mask{ ~(_addr_mask | _neg_addr_mask) & (static_cast<unsigned int>(std::pow(2, _addr_count)) - 1) };

			unsigned int complete_cs = _active_low_cs;
			for (unsigned int cs : css.as<std::vector<unsigned int>>())
				complete_cs ^= cs;

			for (unsigned int addr{ mask }; addr < static_cast<unsigned int>(std::pow(2, _addr_count)); ++addr) {
				unsigned int& cell_val = _rom[(addr & browsing_mask) | mask];

				if (cell_val == _active_low_cs)
					cell_val = complete_cs;
				else
					cell_val |= complete_cs;
			}
		}
		else
			throw std::runtime_error{ "Gen(): Invalid arguments, expected function or table" };

		_addr_mask = addr_mask_backup;
		_neg_addr_mask = neg_addr_mask_backup;
	});
}

void Engine::Generate() {
	_lua.script_file(_script_file);

	std::cout << "Address count: " << _addr_count << std::endl;
	std::cout << "Control Signal count: " << _cs_count << std::endl;
	std::cout << "ROM size: " << _rom.size() << std::endl;
}

void Engine::SaveHex() {
	std::ofstream hex;
	for (unsigned int cs_idx{ 0 }; cs_idx < static_cast<unsigned int>(std::ceil(_cs_count / 8.)); ++cs_idx) {
		const std::string filename{ "out" + std::to_string(cs_idx * 8) + "-" + std::to_string(cs_idx * 8 + 7) + ".hex" };

		hex.open(filename, std::ios::binary);
		if (!hex.is_open())
			throw std::runtime_error{ "Failed to create hex file: " + filename };

		for (auto ucode_word : _rom) {
			hex.put(static_cast<char>((ucode_word >> (cs_idx * 8)) & 0xff));
		}
		hex.close();
	}
}

void Engine::SaveTxt() {
	std::ofstream txt{ "out.txt" };
	if (!txt.is_open())
		throw std::runtime_error{ "Failed to create txt file: 'out.txt'" };

	for (auto ucode_word : _rom)
		txt << std::hex << ucode_word << ' ';

	txt.close();
}