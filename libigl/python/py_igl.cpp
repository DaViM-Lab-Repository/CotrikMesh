// This file is part of libigl, a simple c++ geometry processing library.
//
// Copyright (C) 2017 Sebastian Koch <s.koch@tu-berlin.de> and Daniele Panozzo <daniele.panozzo@gmail.com>
//
// This Source Code Form is subject to the terms of the Mozilla Public License
// v. 2.0. If a copy of the MPL was not distributed with this file, You can
// obtain one at http://mozilla.org/MPL/2.0/.
#include <Eigen/Dense>

#include "python_shared.h"


#include <igl/AABB.h>
#include <igl/ARAPEnergyType.h>
#include <igl/MeshBooleanType.h>
#include <igl/SolverStatus.h>
#include <igl/active_set.h>
#include <igl/adjacency_list.h>
#include <igl/adjacency_matrix.h>
#include <igl/arap.h>
#include <igl/avg_edge_length.h>
#include <igl/barycenter.h>
#include <igl/barycentric_coordinates.h>
#include <igl/barycentric_to_global.h>
#include <igl/bbw.h>
#include <igl/boundary_conditions.h>
#include <igl/boundary_facets.h>
#include <igl/boundary_loop.h>
#include <igl/cat.h>
#include <igl/collapse_edge.h>
#include <igl/colon.h>
#include <igl/column_to_quats.h>
#include <igl/comb_cross_field.h>
#include <igl/comb_frame_field.h>
#include <igl/compute_frame_field_bisectors.h>
#include <igl/cotmatrix.h>
#include <igl/covariance_scatter_matrix.h>
#include <igl/cross_field_missmatch.h>
#include <igl/cut_mesh_from_singularities.h>
#include <igl/deform_skeleton.h>
#include <igl/directed_edge_orientations.h>
#include <igl/directed_edge_parents.h>
#include <igl/doublearea.h>
#include <igl/dqs.h>
#include <igl/edge_lengths.h>
#include <igl/edge_topology.h>
#include <igl/eigs.h>
#include <igl/exact_geodesic.h>
#include <igl/find_cross_field_singularities.h>
#include <igl/fit_rotations.h>
#include <igl/floor.h>
#include <igl/forward_kinematics.h>
#include <igl/gaussian_curvature.h>
#include <igl/get_seconds.h>
#include <igl/grad.h>
#include <igl/harmonic.h>
#include <igl/hsv_to_rgb.h>
#include <igl/internal_angles.h>
#include <igl/invert_diag.h>
#include <igl/is_irregular_vertex.h>
#include <igl/jet.h>
#include <igl/lbs_matrix.h>
#include <igl/local_basis.h>
#include <igl/lscm.h>
#include <igl/map_vertices_to_circle.h>
#include <igl/massmatrix.h>
#include <igl/min_quad_with_fixed.h>
#include <igl/normalize_row_lengths.h>
#include <igl/normalize_row_sums.h>
#include <igl/parula.h>
#include <igl/per_corner_normals.h>
#include <igl/per_edge_normals.h>
#include <igl/per_face_normals.h>
#include <igl/per_vertex_normals.h>
#include <igl/planarize_quad_mesh.h>
#include <igl/point_mesh_squared_distance.h>
#include <igl/polar_svd.h>
#include <igl/principal_curvature.h>
#include <igl/quad_planarity.h>
#include <igl/randperm.h>
#include <igl/readDMAT.h>
#include <igl/readMESH.h>
#include <igl/readOBJ.h>
#include <igl/readOFF.h>
#include <igl/readTGF.h>
#include <igl/read_triangle_mesh.h>
#include <igl/remove_duplicate_vertices.h>
#include <igl/rotate_vectors.h>
#include <igl/setdiff.h>
#include <igl/shape_diameter_function.h>
#include <igl/signed_distance.h>
#include <igl/slice.h>
#include <igl/slice_into.h>
#include <igl/slice_mask.h>
#include <igl/slice_tets.h>
#include <igl/sortrows.h>
#include <igl/triangle_triangle_adjacency.h>
#include <igl/unique.h>
#include <igl/unproject_onto_mesh.h>
#include <igl/upsample.h>
#include <igl/winding_number.h>
#include <igl/writeMESH.h>
#include <igl/writeOBJ.h>
#include <igl/writePLY.h>
#include <igl/readPLY.h>
#include <igl/seam_edges.h>

void python_export_igl(py::module &m)
{
#include "modules/py_typedefs.cpp"

#include "py_igl/py_AABB.cpp"
#include "py_igl/py_ARAPEnergyType.cpp"
#include "py_igl/py_MeshBooleanType.cpp"
#include "py_igl/py_SolverStatus.cpp"
#include "py_igl/py_active_set.cpp"
#include "py_igl/py_adjacency_list.cpp"
#include "py_igl/py_adjacency_matrix.cpp"
#include "py_igl/py_arap.cpp"
#include "py_igl/py_avg_edge_length.cpp"
#include "py_igl/py_barycenter.cpp"
#include "py_igl/py_barycentric_coordinates.cpp"
#include "py_igl/py_barycentric_to_global.cpp"
#include "py_igl/py_bbw.cpp"
#include "py_igl/py_boundary_conditions.cpp"
#include "py_igl/py_boundary_facets.cpp"
#include "py_igl/py_boundary_loop.cpp"
#include "py_igl/py_cat.cpp"
#include "py_igl/py_collapse_edge.cpp"
#include "py_igl/py_colon.cpp"
#include "py_igl/py_column_to_quats.cpp"
#include "py_igl/py_comb_cross_field.cpp"
#include "py_igl/py_comb_frame_field.cpp"
#include "py_igl/py_compute_frame_field_bisectors.cpp"
#include "py_igl/py_cotmatrix.cpp"
#include "py_igl/py_covariance_scatter_matrix.cpp"
#include "py_igl/py_cross_field_missmatch.cpp"
#include "py_igl/py_cut_mesh_from_singularities.cpp"
#include "py_igl/py_deform_skeleton.cpp"
#include "py_igl/py_directed_edge_orientations.cpp"
#include "py_igl/py_directed_edge_parents.cpp"
#include "py_igl/py_doublearea.cpp"
#include "py_igl/py_dqs.cpp"
#include "py_igl/py_edge_lengths.cpp"
#include "py_igl/py_edge_topology.cpp"
#include "py_igl/py_eigs.cpp"
#include "py_igl/py_exact_geodesic.cpp"
#include "py_igl/py_find_cross_field_singularities.cpp"
#include "py_igl/py_fit_rotations.cpp"
#include "py_igl/py_floor.cpp"
#include "py_igl/py_forward_kinematics.cpp"
#include "py_igl/py_gaussian_curvature.cpp"
#include "py_igl/py_get_seconds.cpp"
#include "py_igl/py_grad.cpp"
#include "py_igl/py_harmonic.cpp"
#include "py_igl/py_hsv_to_rgb.cpp"
#include "py_igl/py_internal_angles.cpp"
#include "py_igl/py_invert_diag.cpp"
#include "py_igl/py_is_irregular_vertex.cpp"
#include "py_igl/py_jet.cpp"
#include "py_igl/py_lbs_matrix.cpp"
#include "py_igl/py_local_basis.cpp"
#include "py_igl/py_lscm.cpp"
#include "py_igl/py_map_vertices_to_circle.cpp"
#include "py_igl/py_massmatrix.cpp"
#include "py_igl/py_min_quad_with_fixed.cpp"
#include "py_igl/py_normalize_row_lengths.cpp"
#include "py_igl/py_normalize_row_sums.cpp"
#include "py_igl/py_parula.cpp"
#include "py_igl/py_per_corner_normals.cpp"
#include "py_igl/py_per_edge_normals.cpp"
#include "py_igl/py_per_face_normals.cpp"
#include "py_igl/py_per_vertex_normals.cpp"
#include "py_igl/py_planarize_quad_mesh.cpp"
#include "py_igl/py_point_mesh_squared_distance.cpp"
#include "py_igl/py_polar_svd.cpp"
#include "py_igl/py_principal_curvature.cpp"
#include "py_igl/py_quad_planarity.cpp"
#include "py_igl/py_randperm.cpp"
#include "py_igl/py_readDMAT.cpp"
#include "py_igl/py_readMESH.cpp"
#include "py_igl/py_readOBJ.cpp"
#include "py_igl/py_readOFF.cpp"
#include "py_igl/py_readTGF.cpp"
#include "py_igl/py_read_triangle_mesh.cpp"
#include "py_igl/py_remove_duplicate_vertices.cpp"
#include "py_igl/py_rotate_vectors.cpp"
#include "py_igl/py_setdiff.cpp"
#include "py_igl/py_shape_diameter_function.cpp"
#include "py_igl/py_signed_distance.cpp"
#include "py_igl/py_slice.cpp"
#include "py_igl/py_slice_into.cpp"
#include "py_igl/py_slice_mask.cpp"
#include "py_igl/py_slice_tets.cpp"
#include "py_igl/py_sortrows.cpp"
#include "py_igl/py_triangle_triangle_adjacency.cpp"
#include "py_igl/py_unique.cpp"
#include "py_igl/py_unproject_onto_mesh.cpp"
#include "py_igl/py_upsample.cpp"
#include "py_igl/py_winding_number.cpp"
#include "py_igl/py_writeMESH.cpp"
#include "py_igl/py_writeOBJ.cpp"
#include "py_igl/py_writePLY.cpp"
#include "py_igl/py_readPLY.cpp"
#include "py_igl/py_seam_edges.cpp"
}
