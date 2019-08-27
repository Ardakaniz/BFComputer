#include "Engine.hpp"
#include <iostream>

int main(int argc, char* argv[]) {
	
	std::string script_folder{ "scripts" };
	if (argc >= 2) {
		script_folder = argv[1];
	}

	try {
		Engine engine{ script_folder };
		engine.generate();
		engine.save_hex();
	}
	catch (const sol::error& e) {
		std::cerr << e.what() << std::endl;
		std::cin.get();

		return EXIT_FAILURE;
	}
	catch (const std::runtime_error& e) {
		std::cerr << e.what() << std::endl;
		std::cin.get();

		return EXIT_FAILURE;
	}

	return EXIT_SUCCESS;
}