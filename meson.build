project('druntime', 'd')

phobos_dep = declare_dependency(
    include_directories: ['/usr/include/dmd/phobos/']
)

include = include_directories('src', 'stm32_druntime_backend')

src = [
    #'src/core/internal/entrypoint.d',
    'src/core/demangle.d',
    'src/core/exception.d',
    'src/core/internal/array/capacity.d',
    'src/core/internal/array/equality.d',
    'src/core/internal/array/utils.d',
    'src/core/internal/string.d',
    'src/core/internal/traits.d',
    'src/core/memory.d',
    'src/gc/impl/manual/gc.d',
    'src/object.d',
    'src/rt/aaA.d',
    'src/rt/arraycat.d',
    'src/rt/cast_.d',
    'src/rt/ehalloc.d',
    'src/rt/invariant.d',
    'src/rt/lifetime.d',   
    'src/rt/minfo.d',
    'src/rt/monitor_.d',
    #'src/rt/deh.d',
    #'src/rt/dmain2.d',
    #'src/rt/memory.d',
    'src/rt/sections.d',
    'src/rt/sections_ldc.d',
]

typeinfo_files = [
    'src/rt/typeinfo/ti_Acdouble.d',
    'src/rt/typeinfo/ti_Acfloat.d',
    'src/rt/typeinfo/ti_Acreal.d',
    'src/rt/typeinfo/ti_Adouble.d',
    'src/rt/typeinfo/ti_Afloat.d',
    'src/rt/typeinfo/ti_Ag.d',
    'src/rt/typeinfo/ti_Aint.d',
    'src/rt/typeinfo/ti_Along.d',
    'src/rt/typeinfo/ti_Areal.d',
    'src/rt/typeinfo/ti_Ashort.d',
    'src/rt/typeinfo/ti_byte.d',
    'src/rt/typeinfo/ti_C.d',
    'src/rt/typeinfo/ti_cdouble.d',
    'src/rt/typeinfo/ti_cent.d',
    'src/rt/typeinfo/ti_cfloat.d',
    'src/rt/typeinfo/ti_char.d',
    'src/rt/typeinfo/ti_creal.d',
    'src/rt/typeinfo/ti_dchar.d',
    'src/rt/typeinfo/ti_delegate.d',
    'src/rt/typeinfo/ti_double.d',
    'src/rt/typeinfo/ti_float.d',
    'src/rt/typeinfo/ti_idouble.d',
    'src/rt/typeinfo/ti_ifloat.d',
    'src/rt/typeinfo/ti_int.d',
    'src/rt/typeinfo/ti_ireal.d',
    'src/rt/typeinfo/ti_long.d',
    'src/rt/typeinfo/ti_n.d',
    'src/rt/typeinfo/ti_ptr.d',
    'src/rt/typeinfo/ti_real.d',
    'src/rt/typeinfo/ti_short.d',
    'src/rt/typeinfo/ti_ubyte.d',
    'src/rt/typeinfo/ti_ucent.d',
    'src/rt/typeinfo/ti_uint.d',
    'src/rt/typeinfo/ti_ulong.d',
    'src/rt/typeinfo/ti_ushort.d',
    'src/rt/typeinfo/ti_void.d',
    'src/rt/typeinfo/ti_wchar.d'
]

druntime_dep = library(
    'druntime',
    sources: [src, typeinfo_files],
    include_directories: include,
    dependencies: phobos_dep,
    d_args: ['-defaultlib='],
)
