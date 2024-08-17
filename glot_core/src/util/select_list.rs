use core::cmp::min;
use serde::Deserialize;
use serde::Serialize;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SelectList<T> {
    before: Vec<T>,
    current: T,
    after: Vec<T>,
}

impl<T> SelectList<T>
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

    pub fn from_vec(items: Vec<T>) -> Option<Self> {
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

    pub fn len(&self) -> usize {
        self.to_vec().len()
    }

    pub fn is_empty(&self) -> bool {
        false
    }

    pub fn first(&self) -> T {
        self.before
            .first()
            .cloned()
            .unwrap_or_else(|| self.current.clone())
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
        let items = self.to_vec();
        let capped_index = min(index, items.len() - 1);

        let mut before = items;
        let mut after = before.split_off(capped_index);
        let current = after.remove(0);

        *self = Self {
            before,
            current,
            after,
        }
    }

    pub fn remove_selected(&mut self) {
        let new_items = [self.before.clone(), self.after.clone()].concat();

        if let Some(zip_list) = Self::from_vec(new_items) {
            *self = zip_list;
        }
    }

    pub fn update_selected<F>(&mut self, f: F)
    where
        F: FnOnce(&mut T),
    {
        f(&mut self.current);
    }

    pub fn push(&mut self, item: T) {
        self.after.push(item);
    }

    pub fn select_last(&mut self) {
        let count = self.to_vec().len();
        self.select_index(count - 1);
    }
}
