#pragma once

#include <string>
#include <sstream>
#include <vector>

template<char delimiter>
class Splitter : public std::string {};

template<char delimiter>
std::istream& operator>>(std::istream& is, Splitter<delimiter>& output) {
	std::getline(is, output, delimiter);
	return is;
}

template<char delimiter>
std::vector<std::string> string_split(const std::string& str) {
	std::istringstream iss{ str };

	return std::vector<std::string>(std::istream_iterator<Splitter<delimiter>>(iss),
		std::istream_iterator<Splitter<delimiter>>());
}