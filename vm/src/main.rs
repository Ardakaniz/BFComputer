mod vm;
mod components;
mod value;

use components::*;
use value::*;

fn main() {
	let mut r0 = WordRegister::new();
	let mut zc = WordZeroChecker::new();

	zc.set_input(r0.output.as_const());
	r0.co = true;

	println!("{}", r0.output);
	while !zc.output.get_content()[0] {
		r0.clk(); zc.update();
		println!("{}", r0.output);
	}
}