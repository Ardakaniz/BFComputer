use crate::value::{Value, MutValue, Word, MutWord};
use std::ptr;

pub struct Multiplexer2<V: Value, M: MutValue> {
	input: [*const V; 2],
	pub output: M,

	sigs: (/*s0*/ bool,),
}

impl<V: Value, M: MutValue> Multiplexer2<V, M> {
	pub fn new() -> Self {
		Self {
			input: [ptr::null(); 2],
			output: M::default(),

			sigs: (false,),
		}
	}

	pub fn set_input(&mut self, idx: usize, value: &V) {
		if idx <= 2 {
			self.input[idx] = value;
			self.update();
		}
	}

	pub fn set_ctrl_sigs(&mut self, sigs: (/*s0*/ bool,)) {
		self.sigs = sigs;
		self.update();
	}

	pub fn update(&mut self) {
		let idx = self.sigs.0 as usize;

		if !self.input[idx].is_null() {
			self.output.update(&unsafe{ ptr::read(self.input[idx]) });
		}
		else {
			self.output.set_floating();
		}
	}
}

pub struct Multiplexer3<V: Value, M: MutValue> {
	input: [*const V; 3],
	pub output: M,

	sigs: (/*s0*/ bool, /*s1*/ bool),
}

impl<V: Value, M: MutValue> Multiplexer3<V, M> {
	pub fn new() -> Self {
		Self {
			input: [ptr::null(); 3],
			output: M::default(),

			sigs: (false, false),
		}
	}

	pub fn set_input(&mut self, idx: usize, value: &V) {
		if idx <= 3 {
			self.input[idx] = value;
			self.update();
		}
	}

	pub fn set_ctrl_sigs(&mut self, sigs: (bool, bool)) {
		self.sigs = sigs;
		self.update();
	}

	pub fn update(&mut self) {
		let idx = (self.sigs.0 as usize) | ((self.sigs.1 as usize) << 1);
		
		if idx < 3 && !self.input[idx].is_null() {
			self.output.update(&unsafe{ ptr::read(self.input[idx]) });
		}
		else {
			self.output.set_floating();
		}
	}
}

pub type WordMultiplexer2 = Multiplexer2<Word, MutWord>;
pub type WordMultiplexer3 = Multiplexer3<Word, MutWord>;