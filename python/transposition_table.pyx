from libc.stdlib cimport calloc, free
from libc.stdio cimport printf
from libc.string cimport memset


cdef class TranspositionTable:
    def __cinit__(self, unsigned int num_entries):
        assert num_entries > 0
        self.num_entries = num_entries
        self.H = <Entry *> calloc(num_entries, sizeof(Entry))

        if not self.H:
            raise MemoryError()

    cdef unsigned int _index(self, uint64_t key):
        # cast key to int
        return key % self.num_entries

    cdef void reset(self):
        memset(self.H, 0, self.num_entries * sizeof(Entry))

    cdef void put(self, uint64_t key, uint8_t val):
        assert key < (1LL << 56)

        cdef unsigned int i = self._index(key)
        self.H[i].key = key
        self.H[i].val = val

    cdef uint8_t get(self, uint64_t key):
        assert key < (1LL << 56)
        cdef unsigned int i = self._index(key)

        if self.H[i].key == key:
            return self.H[i].val
        else:
            return 0

    def __dealloc__(self):
        if self.H:
            free(self.H)


cpdef test_transposition_table():
    cdef TranspositionTable tt = TranspositionTable(1000)
    cdef uint64_key
    cdef uint8_t val, true_val, test_val

    key = 4
    true_val = 5

    val = (true_val + STATE_VALUE_OFFSET) | EXACT_FLAG

    tt.put(key, val)
    test_val = tt.get(key)

    printf(b'Val: %hhu, Test Val: %hhu\n', val, test_val)

    assert test_val == val
    assert ((val & STATE_VALUE_MASK) - STATE_VALUE_OFFSET) == true_val

    printf(b'Success!')