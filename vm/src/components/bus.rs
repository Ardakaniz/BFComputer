use crate::value::{Value, MutValue, Bool, Word, MutWord};
use std::ptr;

pub struct Bus<V: Value, M: MutValue> {
	input: Vec<*const V>,
	pub output: M,
}

impl<V: Value, M: MutValue> Bus<V, M> {
	pub fn new() -> Self {
		Self {
			input: vec![],
			output: M::default(),
		}
	}

	pub fn add_input(&mut self, value: &V) {
		self.input.push(value);
		self.update();
	}

	pub fn update(&mut self) {
		self.output.ground();

		for &i in self.input.iter() {
			unsafe {
				if !ptr::read(i).is_floating() {
					let output_bool = self.output.get_content();
					let input_bool = (*i).get_content();

					let mut or = vec![];

					for idx in 0..self.output.size() as usize {
						or.push(match output_bool[idx] || input_bool[idx] {
							true  => Bool::grounded_high(),
							false => Bool::grounded(),
						});
					}

					self.output = M::from_bool_value(&or);
				}
			}
		}
	}
}

pub type WordBus = Bus<Word, MutWord>;