from libc.stdint cimport uint8_t, uint64_t


ctypedef struct Entry:
    uint64_t key
    uint8_t val


ctypedef enum ValFlags:
    EXACT_FLAG = (1 << 6)
    UPPER_BOUND_FLAG = (1 << 7)
    LOWER_BOUND_FLAG = 0
    STATE_VALUE_MASK = 63
    STATE_VALUE_OFFSET = 21


cdef class TranspositionTable:
    cdef Entry * H
    cdef unsigned int num_entries

    cdef unsigned int _index(self, uint64_t key)
    cdef void reset(self)
    cdef void put(self, uint64_t key, uint8_t val)
    cdef uint8_t get(self, uint64_t key)