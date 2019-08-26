use crate::value::{Value, MutValue, Word, MutWord};
use std::ptr;

pub struct Register<V: Value, M: MutValue> {
	pub input: *const V,
	pub output: M,

	pub lo: bool,
	pub co: bool,
	pub up: bool
}

impl<V: Value, M: MutValue> Register<V, M> {
	pub fn new() -> Self {
		Self {
			input: ptr::null(),
			output: M::default(),

			lo: false,
			co: false,
			up: false,
		}
	}

	pub fn clk(&mut self) {
		if self.lo && !self.input.is_null() {
			unsafe { self.output.update(&ptr::read(self.input)); }
		}

		if self.co {
			if self.up {
				self.output.inc();
			}
			else {
				self.output.dec();
			}
		}
	}
}

pub type WordRegister = Register<Word, MutWord>;