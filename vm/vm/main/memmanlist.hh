// Copyright © 2011, Université catholique de Louvain
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// *  Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// *  Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#ifndef __MEMMANLIST_H
#define __MEMMANLIST_H

#include "memmanager.hh"

#include <utility>
#include <cassert>

namespace mozart {

inline
MemoryManager& virtualMMToActualMM(MemoryManager& mm) {
  return mm;
}

////////////////////
// MemManagedList //
////////////////////

template <class T, class MM = MemoryManager&>
class MemManagedList {
private:
  struct ListNode {
    ListNode* next;
    T item;
  };
public:
  struct iterator {
    iterator(ListNode* node) : node(node) {}

    bool operator==(const iterator& other) {
      return node == other.node;
    }

    bool operator!=(const iterator& other) {
      return node != other.node;
    }

    iterator operator++() {
      node = node->next;
      return *this;
    }

    iterator operator++(int) {
      iterator result = *this;
      node = node->next;
      return result;
    }

    iterator operator+(size_t count) {
      iterator result = *this;
      while (count != 0) {
        ++result;
        --count;
      }
      return result;
    }

    T& operator*() {
      return node->item;
    }

    T* operator->() {
      return &node->item;
    }
  private:
    friend class MemManagedList<T, MM>;

    ListNode* node;
  };

  struct removable_iterator {
    removable_iterator(ListNode* node, ListNode* prev) :
      node(node), prev(prev) {}

    bool operator==(const removable_iterator& other) {
      return node == other.node;
    }

    bool operator!=(const removable_iterator& other) {
      return node != other.node;
    }

    removable_iterator operator++() {
      prev = node;
      node = node->next;
      return *this;
    }

    removable_iterator operator++(int) {
      removable_iterator result = *this;
      prev = node;
      node = node->next;
      return result;
    }

    T& operator*() {
      return node->item;
    }

    T* operator->() {
      return &node->item;
    }
  private:
    friend class MemManagedList<T, MM>;

    ListNode* node;
    ListNode* prev;
  };
public:
  MemManagedList() : first(nullptr), last(nullptr) {}

  bool empty() {
    return first == nullptr;
  }

  void push_back(MM mm, const T& item) {
    if (last == nullptr) {
      first = last = newNode(mm, nullptr, item);
    } else {
      last->next = newNode(mm, nullptr, item);
      last = last->next;
    }
  }

  template <class... Args>
  void push_back_new(MM mm, Args&&... args) {
    if (last == nullptr) {
      first = last = newNode_new(mm, nullptr, std::forward<Args>(args)...);
    } else {
      last->next = newNode_new(mm, nullptr, std::forward<Args>(args)...);
      last = last->next;
    }
  }

  void push_front(MM mm, const T& item) {
    if (last == nullptr) {
      first = last = newNode(mm, nullptr, item);
    } else {
      first = newNode(mm, first, item);
    }
  }

  template <class... Args>
  void push_front_new(MM mm, Args&&... args) {
    if (last == nullptr) {
      first = last = newNode_new(mm, nullptr, std::forward<Args>(args)...);
    } else {
      first = newNode_new(mm, first, std::forward<Args>(args)...);
    }
  }

  T pop_front(MM mm) {
    assert(!empty());
    ListNode* node = first;
    T result = node->item;
    first = node->next;
    if (first == nullptr)
      last = nullptr;
    freeNode(mm, node);
    return result;
  }

  T& front() {
    assert(!empty());
    return first->item;
  }

  T& back() {
    assert(!empty());
    return last->item;
  }

  void remove_front(MM mm) {
    assert(!empty());
    ListNode* node = first;
    first = node->next;
    if (first == nullptr)
      last = nullptr;
    freeNode(mm, node);
  }

  void clear(MM mm) {
    ListNode* node = first;

    while (node != nullptr) {
      ListNode* next = node->next;
      freeNode(mm, node);
      node = next;
    }

    first = last = nullptr;
  }

  removable_iterator remove(MM mm, removable_iterator iterator) {
    ListNode* node = iterator.node;
    internalRemove(iterator);
    freeNode(mm, node);
    return iterator;
  }

  void remove(MM mm, removable_iterator first, removable_iterator last) {
    while (first != last)
      first = remove(mm, first);
  }

  void remove_after(MM mm, iterator iter) {
    remove(removable_iterator(iter.node->next, iter.node));
  }

  void remove_after(MM mm, iterator first, iterator last) {
    remove(mm, removable_iterator(first.node->next, first.node),
           removable_iterator(last.node, nullptr /* unused */));
  }

  void splice(MM mm, MemManagedList<T, MM>& source) {
    if (last == nullptr)
      first = source.first;
    else
      last->next = source.first;

    last = source.last;
    source.first = source.last = nullptr;
  }

  void splice(MM mm, MemManagedList<T, MM>& source,
              removable_iterator& srcIterator) {
    ListNode* node = srcIterator.node;
    source.internalRemove(srcIterator);

    node->next = nullptr;

    if (last == nullptr) {
      first = last = node;
    } else {
      last->next = node;
      last = node;
    }
  }

  void insert_before(MM mm, removable_iterator& iterator, const T& item) {
    ListNode* node = newNode(mm, iterator.node, item);
    internalInsert_before(node, iterator);
  }

  template <class... Args>
  void insert_before_new(MM mm, removable_iterator& iterator, Args&&... args) {
    ListNode* node = newNode_new(mm, iterator.node,
                                 std::forward<Args>(args)...);
    internalInsert_before(node, iterator);
  }

  iterator begin() {
    return iterator(first);
  }

  iterator end() {
    return iterator(nullptr);
  }

  removable_iterator removable_begin() {
    return removable_iterator(first, nullptr);
  }

  removable_iterator removable_end() {
    return removable_iterator(nullptr, last);
  }

  /** Size of the list. O(n) operation. */
  size_t size() {
    size_t result = 0;
    for (auto iter = begin(); iter != end(); ++iter)
      result++;
    return result;
  }
private:
  void internalRemove(removable_iterator& iterator) {
    ListNode* node = iterator.node;
    ListNode* prev = iterator.prev;

    iterator.node = node->next;

    if (node == last)
      last = prev;

    if (prev == nullptr)
      first = node->next;
    else
      prev->next = node->next;
  }

  void internalInsert_before(ListNode* node, removable_iterator& iterator) {
    if (iterator.prev == nullptr)
      first = node;
    else
      iterator.prev->next = node;

    if (iterator.node == nullptr)
      last = node;

    iterator.prev = node;
  }
private:
  ListNode* newNode(MM mm, ListNode* next, const T& item) {
    ListNode* node = mallocNode(mm);
    node->next = next;
    node->item = item;
    return node;
  }

  template <class... Args>
  ListNode* newNode_new(MM mm, ListNode* next, Args&&... args) {
    ListNode* node = mallocNode(mm);
    node->next = next;
    new (&node->item) T(std::forward<Args>(args)...);
    return node;
  }

  ListNode* mallocNode(MM mm) {
    return static_cast<ListNode*>(
      virtualMMToActualMM(mm).malloc(sizeof(ListNode)));
  }

  void freeNode(MM mm, ListNode* node) {
    virtualMMToActualMM(mm).free(
      static_cast<void*>(node), sizeof(ListNode));
  }

  ListNode* first;
  ListNode* last;
};

}

#endif // __MEMMANLIST_H
