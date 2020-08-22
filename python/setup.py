try:
    from setuptools import setup
except ImportError:
    from distutils.core import setup

# from distutils.core import setup
from Cython.Build import cythonize


setup(
    ext_modules=cythonize([
        'minimax.pyx',
        'board.pyx',
        'transposition_table.pyx',
        'play.pyx',
        'move_sorter.pyx',
        'opening_book.pyx',
    ], annotate=True, force=True, compiler_directives={'language_level': '3'})
)