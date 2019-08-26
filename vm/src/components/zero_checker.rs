use crate::value::{Value, MutValue, Bool, Word, MutWord};
use std::ptr;

pub struct ZeroChecker<V: Value, M: MutValue> {
	input: *const V,
	pub output: M,
}

impl<V: Value, M: MutValue> ZeroChecker<V, M> {
	pub fn new() -> Self {
		Self {
			input: ptr::null(),
			output: M::default(),
		}
	}

	pub fn set_input(&mut self, value: &V) {
		self.input = value;
		self.update();
	}

	pub fn update(&mut self) {
		let bool_value =
			match unsafe { self.input.as_ref() } {
				Some(inp) => inp.get_content().iter().all(|&x| x == false),
				None       => false,
			};

		self.output =
			if bool_value {
				M::grounded_high()
			}
			else {
				M::grounded()
			};
	}
}

pub type WordZeroChecker = ZeroChecker<Word, MutWord>;