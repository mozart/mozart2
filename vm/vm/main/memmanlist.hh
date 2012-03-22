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

#include <cassert>

namespace mozart {

////////////////////
// MemManagedList //
////////////////////

template <class T>
struct MemManagedList {
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

    T& operator*() {
      return node->item;
    }

    T* operator->() {
      return &node->item;
    }
  private:
    ListNode* node;
  };
public:
  MemManagedList() : first(nullptr), last(nullptr) {}

  bool empty() {
    return first == nullptr;
  }

  void push_back(MemoryManager& mm, const T& item) {
    if (last == nullptr) {
      first = last = newNode(mm, nullptr, item);
    } else {
      last->next = newNode(mm, nullptr, item);
      last = last->next;
    }
  }

  template <class... Args>
  void push_back_new(MemoryManager& mm, Args... args) {
    if (last == nullptr) {
      first = last = newNode_new(mm, nullptr, args...);
    } else {
      last->next = newNode_new(mm, nullptr, args...);
      last = last->next;
    }
  }

  void push_front(MemoryManager& mm, const T& item) {
    if (last == nullptr) {
      first = last = newNode(mm, nullptr, item);
    } else {
      first = newNode(mm, first, item);
    }
  }

  template <class... Args>
  void push_front_new(MemoryManager& mm, Args... args) {
    if (last == nullptr) {
      first = last = newNode_new(mm, nullptr, args...);
    } else {
      first = newNode_new(mm, first, args...);
    }
  }

  T pop_front(MemoryManager& mm) {
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

  void remove_front(MemoryManager& mm) {
    assert(!empty());
    ListNode* node = first;
    first = node->next;
    if (first == nullptr)
      last = nullptr;
    freeNode(mm, node);
  }

  void clear(MemoryManager& mm) {
    ListNode* node = first;

    while (node != nullptr) {
      ListNode* next = node->next;
      freeNode(mm, node);
      node = next;
    }

    first = last = nullptr;
  }

  void splice(MemoryManager& mm, MemManagedList<T>& source) {
    if (last == nullptr)
      first = source.first;
    else
      last->next = source.first;

    last = source.last;
    source.first = source.last = nullptr;
  }

  iterator begin() {
    return iterator(first);
  }

  iterator end() {
    return iterator(nullptr);
  }

  /** Size of the list. O(n) operation. */
  size_t size() {
    size_t result = 0;
    for (auto iter = begin(); iter != end(); ++iter)
      result++;
    return result;
  }
private:
  ListNode* newNode(MemoryManager& mm, ListNode* next, const T& item) {
    void* memory = mm.malloc(sizeof(ListNode));
    ListNode* node = static_cast<ListNode*>(memory);
    node->next = next;
    node->item = item;
    return node;
  }

  template <class... Args>
  ListNode* newNode_new(MemoryManager& mm, ListNode* next, Args... args) {
    void* memory = mm.malloc(sizeof(ListNode));
    ListNode* node = static_cast<ListNode*>(memory);
    node->next = next;
    new (&node->item) T(args...);
    return node;
  }

  void freeNode(MemoryManager& mm, ListNode* node) {
    mm.free(static_cast<void*>(node), sizeof(ListNode));
  }

  ListNode* first;
  ListNode* last;
};

}

#endif // __MEMMANLIST_H
