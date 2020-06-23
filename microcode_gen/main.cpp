#include "Engine.hpp"
#include <iostream>

int main(int argc, char* argv[]) {
	std::string script_file{ "script.lua" };
	bool save_txt{ false };
	if (argc >= 2) {
		if (argv[1][0] == '-') { // Beurk
			save_txt = (std::string{ argv[1] } == "-txt");
		}
		else
			script_file = argv[1];
	}

	try {
		Engine engine{ script_file };
		engine.Generate();

		if (!save_txt) {
			engine.SaveTxt();
			std::cout << "Saving txt format" << std::endl;
		}
		else
			engine.SaveHex();
	}
	catch (const sol::error & e) {
		std::cerr << e.what() << std::endl;
		std::cin.get();

		return EXIT_FAILURE;
	}
	catch (const std::runtime_error & e) {
		std::cerr << e.what() << std::endl;
		std::cin.get();

		return EXIT_FAILURE;
	}

	return EXIT_SUCCESS;
}