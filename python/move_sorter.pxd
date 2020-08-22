from libc.stdint cimport uint64_t


ctypedef struct ScoredMove:
    uint64_t move
    int score
    ScoredMove * next

# Linked list
cdef class SortedMoveList:
    cdef int size
    cdef ScoredMove * entries

    cdef void add(self, uint64_t move, int score) except *
    cdef uint64_t getNext(self)
    cdef void print_moves(self)
    cdef void reset(self)
