use std::convert::TryInto;
use std::fmt;

pub trait Value {
	type UnderlyingType;

	fn floating()      -> Self where Self: Sized;
	fn grounded()      -> Self where Self: Sized;
	fn grounded_high() -> Self where Self: Sized;
	fn default()       -> Self where Self: Sized;
	fn from_bool_value(values: &Vec<Bool>) -> Self where Self: Sized;

	fn size(&self) -> u32;

	fn is_floating(&self)     -> bool;
	fn get_content(&self)     -> &[bool];
	fn into_bool_value(&self) -> Vec<Bool>;
}

pub trait MutValue : Value {
	type ConstValue: Value;

	fn as_const(&self) -> &Self::ConstValue;
	fn inc(&mut self);
	fn dec(&mut self);
	fn ground(&mut self);
	fn set_floating(&mut self);
	fn update(&mut self, other: &impl Value);
}

macro_rules! value_type {
	($n:ident, $m:ident, $t:ty, $s:expr) => {
		#[derive(Debug, Copy, Clone)]
		pub struct $n {
			content: [bool; $s],
			floating: bool,
		}

		impl $n {
			fn make_random_content() -> [bool; $s] {
				let mut content = [false; $s];
				for elem in content.iter_mut() {
					*elem = rand::random();
				}

				content
			}
		}

		impl Value for $n {
			type UnderlyingType = $t;

			fn floating() -> Self {
				Self { content: Self::make_random_content(), floating: true }
			}

			fn grounded() -> Self {
				Self { content: [false; $s], floating: false }
			}

			fn grounded_high() -> Self {
				Self { content: [true; $s], floating: false }
			}

			fn default() -> Self {
				Self { content: Self::make_random_content(), floating: false }
			}

			fn from_bool_value(values: &Vec<Bool>) -> Self {
				let mut content = [false; $s];

				for (i, v) in values.iter().enumerate() {
					if i >= $s {
						break;
					}

					content[i] = v.get_content()[0];
				}

				Self { content, floating: false }
			}

			fn size(&self) -> u32 {
				$s
			}

			fn is_floating(&self) -> bool {
				self.floating
			}

			fn get_content(&self) -> &[bool] {
				&self.content
			}

			fn into_bool_value(&self) -> Vec<Bool> {
				let mut out = vec![];
				for c in self.content.iter() {
					out.push(
						match c {
							true  => Bool::grounded_high(),
							false => Bool::grounded(),
						});
				}

				out
			}
		}

		impl fmt::Display for $n {
			fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
				if self.floating {
					let mut output = String::new();
					for _ in 0..$s {
						output += "f";
					}

					write!(f, "{}", output)
				}
				else {
					let mut output = 0u64;
					for (i, &b) in self.content.iter().enumerate().rev() {
						if b {
							output |= 2u64.pow(i as u32);
						}
					}

					write!(f, "{}", output)
				}

			}
		}

		impl fmt::Binary for $n {
			fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
				let mut output = String::new();

				for &b in self.content.iter().rev() {
					output +=
						if self.floating {
							"f"
						}
						else if b {
							"1"
						}
						else {
							"0"
						};
				}

				write!(f, "{}", output)
			}
		}

		#[derive(Debug, Copy, Clone)]
		pub struct $m {
			inner_value: $n
		}

		impl Value for $m {
			type UnderlyingType = $t;

			fn floating() -> Self {
				Self { inner_value: $n::floating() }
			}

			fn grounded() -> Self {
				Self { inner_value: $n::grounded() }
			}

			fn grounded_high() -> Self {
				Self { inner_value: $n::grounded_high() }
			}

			fn default() -> Self {
				Self { inner_value: $n::default() }
			}

			fn from_bool_value(values: &Vec<Bool>) -> Self {
				Self { inner_value: $n::from_bool_value(values) }
			}


			fn size(&self) -> u32 {
				$s
			}

			fn is_floating(&self) -> bool {
				self.inner_value.is_floating()
			}

			fn get_content(&self) -> &[bool] {
				self.inner_value.get_content()
			}

			fn into_bool_value(&self) -> Vec<Bool> {
				self.inner_value.into_bool_value()
			}
		}

		impl MutValue for $m {
			type ConstValue = $n;

			fn as_const(&self) -> &Self::ConstValue {
				&self.inner_value
			}

			fn inc(&mut self) {
				let mut flip_next = true;
				for b in self.inner_value.content.iter_mut()/*.rev()*/ {
					if flip_next {
						*b ^= true; // a xor true <=> a = !a
						flip_next = *b == false; // we went from 1 to 0 so we must flip the next bit
					}
				}
			}

			fn dec(&mut self) {
				let mut flip_next = true;
				for b in self.inner_value.content.iter_mut() {
					if flip_next {
						*b ^= true; // a xor true <=> a = !a
						flip_next = *b == true; // we went from 0 to 1 so we must flip the next bit
					}
				}
			}

			fn ground(&mut self) {
				self.inner_value.content = [false; $s];
				self.inner_value.floating = false;
			}

			fn set_floating(&mut self) {
				self.inner_value.floating = true;
			}

			fn update(&mut self, other: &impl Value) {
				let mut sized_content = other.get_content().iter().cloned().collect::<Vec<_>>();
				sized_content.resize($s, false);

				self.inner_value.content = sized_content.as_slice().try_into().unwrap();
				self.inner_value.floating = other.is_floating();
			}
		}

		impl fmt::Display for $m {
			fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
				write!(f, "{}", self.inner_value)
			}
		}

		impl fmt::Binary for $m {
			fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
				write!(f, "{:b}", self.inner_value)
			}
		}

		impl Into<$t> for $m {
			fn into(self) -> $t {
				self.inner_value.into()
			}
		}
	};
}

macro_rules! impl_into_num {
	($t:ty) => {
		mod _ {
			type UnderlyingT = $t;
			impl Into<UnderlyingT::UnderlyingType> for $t {
				fn into(self) -> UnderlyingT::UnderlyingType {
					let mut output: UnderlyingT::UnderlyingType = 0;
					for (i, &b) in value.get_content().iter().enumerate().rev() {
						if b {
							output |= 2u64.pow(i as u32);
						}
					}
					
					output
				}
			}
		}
	};
}

pub type CtrlAddrWord = Word;
pub type MutCtrlAddrWord = MutWord;
pub type BiggestWord = CtrlSigWord;
pub type MutBiggestWord = MutCtrlSigWord;

value_type!(Bool, MutBool, bool, 1);
value_type!(CtrlSigWord, MutCtrlSigWord, u32, 25);
value_type!(InstrWord, MutInstrWord, u8, 3);
value_type!(PhaseWord, MutPhaseWord, (bool, bool), 2);
value_type!(Word, MutWord, u16, 12);

impl_into_num!(CtrlSigWord);
impl_into_num!(InstrWord);
impl_into_num!(Word);

impl Into<bool> for Bool {
	fn into(self) -> bool {
		self.get_content()[0]
	}
}

#[macro_export]
macro_rules! pack {
	($($val:ident $(,)?)*) => {
		&pack![@intern $($val,)*]()
	};

	(@intern $($val:ident $(,)?)*) => {
		|| {
			let mut packed = vec![];

			$(for c in $val.into_bool_value() {
				packed.push(c);
			})*

			packed
		}
	}
}