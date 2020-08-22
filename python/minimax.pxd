from libc.stdint cimport uint64_t

cdef int alpha_beta_negamax_search(uint64_t position, uint64_t mask, int depth, int alpha, int beta) except *