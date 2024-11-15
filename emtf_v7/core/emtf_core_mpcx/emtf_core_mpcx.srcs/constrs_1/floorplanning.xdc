create_pblock pblock_ptlut
add_cells_to_pblock [get_pblocks pblock_ptlut] [get_cells -quiet [list ptlut]]
resize_pblock [get_pblocks pblock_ptlut] -add {SLICE_X0Y355:SLICE_X221Y499}
resize_pblock [get_pblocks pblock_ptlut] -add {DSP48_X0Y142:DSP48_X17Y199}
resize_pblock [get_pblocks pblock_ptlut] -add {RAMB18_X0Y142:RAMB18_X14Y199}
resize_pblock [get_pblocks pblock_ptlut] -add {RAMB36_X0Y71:RAMB36_X14Y99}

create_pblock pblock_120MHz
add_cells_to_pblock [get_pblocks pblock_120MHz] [get_cells -quiet [list core/nn core/ser_phmatch_and_deltas]]
resize_pblock [get_pblocks pblock_120MHz] -add {SLICE_X0Y0:SLICE_X221Y183}
resize_pblock [get_pblocks pblock_120MHz] -add {DSP48_X0Y0:DSP48_X17Y71}
resize_pblock [get_pblocks pblock_120MHz] -add {RAMB18_X0Y0:RAMB18_X14Y71}
resize_pblock [get_pblocks pblock_120MHz] -add {RAMB36_X0Y0:RAMB36_X14Y35}