use crate::value::{Value, MutValue, Word, MutWord};
use std::ptr;

pub struct RAM {
	pub address_in: *const Word,
	pub data_in: *const Word,
	pub data_out: MutWord,

	pub we: bool,
	pub oe: bool,

	content: [MutWord; 4096]
}

impl RAM {
	pub fn new() -> Self {
		Self {
			address_in: ptr::null(),
			data_in: ptr::null(),
			data_out: MutWord::default(),

			we: false,
			oe: false,

			content: [MutWord::default(); 4096]
		}
	}

	pub fn clk(&mut self) {
		unsafe {
			if let Some(address_in) = self.address_in.as_ref() {
				if self.we {
					(&ptr::read(self.data_in)); 
				}
				else if self.oe && !self.address_in.is_null() {
					self.data_out.update(self.content[address_in])
				}
			}
		}
	}
}