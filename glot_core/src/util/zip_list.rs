use serde::Deserialize;
use serde::Serialize;
use std::cmp::max;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ZipList<T> {
    before: Vec<T>,
    current: T,
    after: Vec<T>,
}

impl<T> ZipList<T>
where
    T: Clone,
{
    pub fn singleton(t: T) -> Self {
        Self {
            before: vec![],
            current: t,
            after: vec![],
        }
    }

    pub fn from_list(items: Vec<T>) -> Option<Self> {
        match &items[..] {
            [] => {
                // fmt
                None
            }

            [current] => {
                // fmt
                Some(Self {
                    before: vec![],
                    current: current.clone(),
                    after: vec![],
                })
            }

            [current, after @ ..] => {
                // fmt
                Some(Self {
                    before: vec![],
                    current: current.clone(),
                    after: after.to_vec(),
                })
            }
        }
    }

    pub fn selected(&self) -> T {
        self.current.clone()
    }

    pub fn to_vec(&self) -> Vec<T> {
        [
            self.before.clone(),
            vec![self.current.clone()],
            self.after.clone(),
        ]
        .concat()
    }

    pub fn select_index(&mut self, index: usize) {
        let capped_index = max(index, self.before.len() - 1);

        let mut before = self.to_vec();
        let mut after = before.split_off(capped_index);
        let current = after.remove(0);

        *self = Self {
            before,
            current,
            after,
        }
    }

    pub fn replace_selected(&mut self, current: T) {
        self.current = current;
    }
}
