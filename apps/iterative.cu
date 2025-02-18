/* =========================================================================
   Copyright (c) 2010-2016, Institute for Microelectronics,
                            Institute for Analysis and Scientific Computing,
                            TU Wien.
   Portions of this software are copyright by UChicago Argonne, LLC.

                            -----------------
                  ViennaCL - The Vienna Computing Library
                            -----------------

   Project Head:    Karl Rupp                   rupp@iue.tuwien.ac.at

   (A list of authors and contributors can be found in the PDF manual)

   License:         MIT (X11), see file LICENSE in the base directory
============================================================================= */

/** \example iterative.cpp
*
*   This tutorial explains the use of iterative solvers in ViennaCL.
*
*   \note iterative.cpp and iterative.cu are identical, the latter being required for compilation using CUDA nvcc
*
*   We start with including the necessary system headers:
**/

//
// include necessary system headers
//
#include <iostream>

//
// Necessary to obtain a suitable performance in ublas
#ifndef NDEBUG
 #define BOOST_UBLAS_NDEBUG
#endif

//
// ublas includes
//
#include <boost/numeric/ublas/io.hpp>
#include <boost/numeric/ublas/triangular.hpp>
#include <boost/numeric/ublas/matrix_sparse.hpp>
#include <boost/numeric/ublas/matrix.hpp>
#include <boost/numeric/ublas/matrix_proxy.hpp>
#include <boost/numeric/ublas/operation.hpp>
#include <boost/numeric/ublas/operation_sparse.hpp>
#include <boost/numeric/ublas/io.hpp>
#include <boost/numeric/ublas/lu.hpp>

// Must be set if you want to use ViennaCL algorithms on ublas objects
#define VIENNACL_WITH_UBLAS 1


//
// ViennaCL includes
//
#include "viennacl/scalar.hpp"
#include "viennacl/vector.hpp"
#include "viennacl/compressed_matrix.hpp"
#include "viennacl/coordinate_matrix.hpp"
#include "viennacl/linalg/prod.hpp"
#include "viennacl/linalg/ilu.hpp"
#include "viennacl/linalg/jacobi_precond.hpp"
#include "viennacl/linalg/cg.hpp"
#include "viennacl/linalg/bicgstab.hpp"
#include "viennacl/linalg/gmres.hpp"
#include "viennacl/io/matrix_market.hpp"


// Some helper functions for this tutorial:
#include "vector-io.hpp"

/**
*  A shortcut for convience (use `ublas::` instead of `boost::numeric::ublas::`)
**/
using namespace boost::numeric;


#include "MeshFileReader.h"
#include "MeshFileWriter.h"
#include "EdgeLines.h"
#include "MeshOpt.h"
#include <iostream>
#include "ArgumentManager.h"
/**
*  In the main() routine we create matrices and vectors using Boost.uBLAS types and fill them with data.
*  Then, ViennaCL types are created and the data is copied from the respective Boost.uBLAS objects.
*  Various preconditioners are set up and finally the iterative solvers get called.
**/
int main(int argc, char* argv[])
{
    typedef float       ScalarType;

    if (argc < 2)
    {
        std::cout << "Usage: MeshOpt <file>\n";
        return -1;
    }
    MeshFileReader reader(argv[1]);
    Mesh& mesh = (Mesh&)reader.GetMesh();
    mesh.BuildAllConnectivities();
    mesh.ExtractBoundary();
    mesh.ExtractSingularities();
    mesh.BuildParallelE();
    mesh.BuildConsecutiveE();
    mesh.BuildOrthogonalE();

    MeshOpt meshOpt(mesh);
    meshOpt.SetAlpha(1000);
    meshOpt.SetBeta(1000);
    meshOpt.SetGamma(1.0);
    meshOpt.ComputeAvgEdgeLength();
    std::cout << "=============================\n";
    std::cout << "   Computing TargetLength    \n";

    std::vector<Trip> coefficients;
    std::vector<float> b;
    size_t row  = 0;
    size_t numOfparallelEids = 0;
    size_t numOfconsecutiveEids = 0;
    for (size_t i = 0; i < mesh.E.size(); i++)
    {
        coefficients.push_back(Trip(row, i, 1));
        if (mesh.E[i].isBoundary)
            b.push_back(mesh.E[i].length);
//        else if (mesh.E[i].isSingularity)
//            b.push_back(0.5 * avgMeshEdgeLength);
        else
            b.push_back(0.025);
        row++;

        for (size_t j = 0; j < mesh.E[i].parallelEids.size(); j++)
        {
            size_t N_Eid = mesh.E[i].parallelEids[j];
            coefficients.push_back(Trip(row, i, 1));
            coefficients.push_back(Trip(row, N_Eid, -1));
            b.push_back(0);
            numOfparallelEids++;
            row++;
        }
        for (size_t j = 0; j < mesh.E[i].consecutiveEids.size(); j++)
        {
            size_t N_Eid = mesh.E[i].consecutiveEids[j];
            coefficients.push_back(Trip(row, i, 1));
            coefficients.push_back(Trip(row, N_Eid, -1));
            b.push_back(0);
            numOfconsecutiveEids++;
            row++;
        }
    }

    for (size_t k = 0; k < mesh.E.size(); k++){
        const Edge& edge = mesh.E.at(k);
        if (!edge.isSingularity)
            continue;
        if (edge.N_Cids.size() != 5 && edge.N_Cids.size() != 3 && edge.N_Cids.size() != 6)
            continue;
        for (size_t j = 0; j < edge.orthogonalEids.size(); j++) {
            for (size_t i = 0; i < edge.orthogonalEids.size(); i++) {
                if (j == i)
                    continue;
                const size_t edgeId1 = edge.orthogonalEids.at(j);
                const size_t edgeId2 = edge.orthogonalEids.at(i);
                /*const */ Edge& edge1 = mesh.E.at(edgeId1);
                /*const */ Edge& edge2 = mesh.E.at(edgeId2);
                const size_t vId1_1 = edge1.Vids.at(0);
                const size_t vId1_2 = edge1.Vids.at(1);
                const size_t vId2_1 = edge2.Vids.at(0);
                const size_t vId2_2 = edge2.Vids.at(1);
                if (vId1_1 != vId2_1 &&
                    vId1_1 != vId2_2 &&
                    vId1_2 != vId2_1 &&
                    vId1_2 != vId2_2)
                    continue;

                coefficients.push_back(Trip(row, edge1.id, 1));
                coefficients.push_back(Trip(row, edge2.id, -1));
                b.push_back(0);
                row++;
            }
        }
    }

    size_t col = mesh.E.size();

    Eigen::SparseMatrix<float> A(row, col);
    A.setFromTriplets(coefficients.begin(), coefficients.end());
    Eigen::SparseMatrix<float> A_T = A.transpose();
    Eigen::SparseMatrix<float> ATA = A_T * A;
    //  MatrixXf ;
    VectorXf X(col), B(row);
    for (size_t i = 0; i < row; i++)
        B(i) = b[i];

    VectorXf ATB = A_T * B;
///////////////////////////////////////////////////////////////////////////////////
    //Eigen::SimplicialLDLT<SpMat> chol(ATA);
    //X = chol.solve(ATB);


    /**
    * Set up some ublas objects
    **/
    ublas::vector<ScalarType> rhs(ATB.size());
    ublas::vector<ScalarType> ref_result;
    ublas::vector<ScalarType> result;
    ublas::compressed_matrix<ScalarType> ublas_matrix;

    for (size_t i = 0; i < ATB.size(); i++)
        rhs[i] = ATB(i);


    /**
    * Set up some ViennaCL objects
    **/
    std::size_t vcl_size = rhs.size();
    viennacl::compressed_matrix<ScalarType> vcl_compressed_matrix;
    viennacl::coordinate_matrix<ScalarType> vcl_coordinate_matrix;
    viennacl::vector<ScalarType> vcl_rhs(vcl_size);
    viennacl::vector<ScalarType> vcl_result(vcl_size);
    viennacl::vector<ScalarType> vcl_ref_result(vcl_size);

    viennacl::copy(rhs.begin(), rhs.end(), vcl_rhs.begin());
    viennacl::copy(ref_result.begin(), ref_result.end(), vcl_ref_result.begin());


    /**
    * Transfer ublas-matrix to GPU:
    **/
    viennacl::copy(ublas_matrix, vcl_compressed_matrix);

    /**
    * An alternative way is to use the C++ STL.
    * In such case, the sparse matrix is represented as a std::vector< std::map< unsigned int, ScalarType> >
    * After the instantiation, the data from the uBLAS matrix is copied over to the STL-matrix, which is then copied over to a ViennaCL matrix.
    * This step is just for demonstration purposes.
    **/
    std::vector< std::map< unsigned int, ScalarType> > stl_matrix(rhs.size());

    for (int k = 0; k < ATA.outerSize(); ++k) {
        for (SparseMatrix<float>::InnerIterator it(ATA, k); it; ++it) {
            stl_matrix[it.row()][it.col()] = it.value();
        }
    }

    std::vector<ScalarType> stl_rhs(rhs.size()), stl_result(result.size());
    std::copy(rhs.begin(), rhs.end(), stl_rhs.begin());
    viennacl::copy(stl_matrix, vcl_coordinate_matrix);
    viennacl::copy(vcl_coordinate_matrix, stl_matrix);
    stl_result = viennacl::linalg::solve(stl_matrix, stl_rhs, viennacl::linalg::gmres_tag());
    //stl_result = viennacl::linalg::solve(stl_matrix, stl_rhs, viennacl::linalg::gmres_tag(1e-6, 20), vcl_ilut);
    //stl_result = viennacl::linalg::solve(stl_matrix, stl_rhs, viennacl::linalg::gmres_tag(1e-6, 20), vcl_jacobi);

    std::ofstream ofs("cudax.txt");
    for (size_t i = 0; i < stl_result.size(); i++)
        ofs << stl_result[i] << std::endl;
//////////////////////////////////////////////////////////////////////////////////
    for (size_t i = 0; i < mesh.E.size(); i++)
        mesh.E[i].length = X[i];

    std::cout << "=============================\n";





//  /**
//  * Set up some ublas objects
//  **/
//  ublas::vector<ScalarType> rhs;
//  ublas::vector<ScalarType> ref_result;
//  ublas::vector<ScalarType> result;
//  ublas::compressed_matrix<ScalarType> ublas_matrix;
//
//  /**
//  * Read system matrix from a matrix-market file
//  **/
//  if (!viennacl::io::read_matrix_market_file(ublas_matrix, "../examples/testdata/mat65k.mtx"))
//  {
//    std::cout << "Error reading Matrix file" << std::endl;
//    return EXIT_FAILURE;
//  }
//
//  if (!readVectorFromFile("../examples/testdata/rhs65025.txt", rhs))
//  {
//    std::cout << "Error reading RHS file" << std::endl;
//    return EXIT_FAILURE;
//  }
//
//  if (!readVectorFromFile("../examples/testdata/result65025.txt", ref_result))
//  {
//    std::cout << "Error reading Result file" << std::endl;
//    return EXIT_FAILURE;
//  }
//
//  /**
//  * Set up some ViennaCL objects
//  **/
//  std::size_t vcl_size = rhs.size();
//  viennacl::compressed_matrix<ScalarType> vcl_compressed_matrix;
//  viennacl::coordinate_matrix<ScalarType> vcl_coordinate_matrix;
//  viennacl::vector<ScalarType> vcl_rhs(vcl_size);
//  viennacl::vector<ScalarType> vcl_result(vcl_size);
//  viennacl::vector<ScalarType> vcl_ref_result(vcl_size);
//
//  viennacl::copy(rhs.begin(), rhs.end(), vcl_rhs.begin());
//  viennacl::copy(ref_result.begin(), ref_result.end(), vcl_ref_result.begin());
//
//
//  /**
//  * Transfer ublas-matrix to GPU:
//  **/
//  viennacl::copy(ublas_matrix, vcl_compressed_matrix);
//
//  /**
//  * An alternative way is to use the C++ STL.
//  * In such case, the sparse matrix is represented as a std::vector< std::map< unsigned int, ScalarType> >
//  * After the instantiation, the data from the uBLAS matrix is copied over to the STL-matrix, which is then copied over to a ViennaCL matrix.
//  * This step is just for demonstration purposes.
//  **/
//  std::vector< std::map< unsigned int, ScalarType> > stl_matrix(rhs.size());
//  for (ublas::compressed_matrix<ScalarType>::iterator1 iter1 = ublas_matrix.begin1();
//       iter1 != ublas_matrix.end1();
//       ++iter1)
//  {
//    for (ublas::compressed_matrix<ScalarType>::iterator2 iter2 = iter1.begin();
//         iter2 != iter1.end();
//         ++iter2)
//         stl_matrix[iter2.index1()][static_cast<unsigned int>(iter2.index2())] = *iter2;
//  }
//  std::vector<ScalarType> stl_rhs(rhs.size()), stl_result(result.size());
//  std::copy(rhs.begin(), rhs.end(), stl_rhs.begin());
//  viennacl::copy(stl_matrix, vcl_coordinate_matrix);
//  viennacl::copy(vcl_coordinate_matrix, stl_matrix);
//
//  /**
//  * Set up ILUT preconditioners for ublas and ViennaCL objects:
//  **/
//  std::cout << "Setting up preconditioners for uBLAS-matrix..." << std::endl;
//  viennacl::linalg::ilut_precond< ublas::compressed_matrix<ScalarType> >    ublas_ilut(ublas_matrix, viennacl::linalg::ilut_tag());
//  viennacl::linalg::ilu0_precond< ublas::compressed_matrix<ScalarType> >    ublas_ilu0(ublas_matrix, viennacl::linalg::ilu0_tag());
//  viennacl::linalg::block_ilu_precond< ublas::compressed_matrix<ScalarType>,
//                                       viennacl::linalg::ilu0_tag>          ublas_block_ilu0(ublas_matrix, viennacl::linalg::ilu0_tag());
//
//  std::cout << "Setting up preconditioners for ViennaCL-matrix..." << std::endl;
//  viennacl::linalg::ilut_precond< viennacl::compressed_matrix<ScalarType> > vcl_ilut(vcl_compressed_matrix, viennacl::linalg::ilut_tag());
//  viennacl::linalg::ilu0_precond< viennacl::compressed_matrix<ScalarType> > vcl_ilu0(vcl_compressed_matrix, viennacl::linalg::ilu0_tag());
//  viennacl::linalg::block_ilu_precond< viennacl::compressed_matrix<ScalarType>,
//                                       viennacl::linalg::ilu0_tag>          vcl_block_ilu0(vcl_compressed_matrix, viennacl::linalg::ilu0_tag());
//
//  /**
//  * set up Jacobi preconditioners for ViennaCL and ublas objects:
//  **/
//  viennacl::linalg::jacobi_precond< ublas::compressed_matrix<ScalarType> >    ublas_jacobi(ublas_matrix, viennacl::linalg::jacobi_tag());
//  viennacl::linalg::jacobi_precond< viennacl::compressed_matrix<ScalarType> > vcl_jacobi(vcl_compressed_matrix, viennacl::linalg::jacobi_tag());
//
//  /**
//  * <h2>Conjugate Gradient Solver</h2>
//  **/
//  std::cout << "----- CG Method -----" << std::endl;
//
//  /**
//  * Run the CG method with uBLAS objects.
//  * Use a relative tolerance of \f$ 10^{-6} \f$ and a maximum of 20 iterations when using ILUT or Jacobi preconditioners.
//  * You might need higher iteration counts for poorly conditioned systems.
//  **/
//  result = viennacl::linalg::solve(ublas_matrix, rhs, viennacl::linalg::cg_tag());
//  result = viennacl::linalg::solve(ublas_matrix, rhs, viennacl::linalg::cg_tag(1e-6, 20), ublas_ilut);
//  result = viennacl::linalg::solve(ublas_matrix, rhs, viennacl::linalg::cg_tag(1e-6, 20), ublas_jacobi);
//
//
//  /**
//  * Run the CG method for ViennaCL objects.
//  * The results here should be the same as with uBLAS objects (at least up to round-off error).
//  **/
//  vcl_result = viennacl::linalg::solve(vcl_compressed_matrix, vcl_rhs, viennacl::linalg::cg_tag());
//  vcl_result = viennacl::linalg::solve(vcl_compressed_matrix, vcl_rhs, viennacl::linalg::cg_tag(1e-6, 20), vcl_ilut);
//  vcl_result = viennacl::linalg::solve(vcl_compressed_matrix, vcl_rhs, viennacl::linalg::cg_tag(1e-6, 20), vcl_jacobi);
//
//  /**
//  * Convenience option: Run the CG method by passing STL types. This will use appropriate ViennaCL objects internally.
//  * You need to include viennacl/compressed_matrix.hpp and viennacl/vector.hpp before viennacl/linalg/cg.hpp for this to work!
//  **/
//  stl_result = viennacl::linalg::solve(stl_matrix, stl_rhs, viennacl::linalg::cg_tag());
//  stl_result = viennacl::linalg::solve(stl_matrix, stl_rhs, viennacl::linalg::cg_tag(1e-6, 20), vcl_ilut);
//  stl_result = viennacl::linalg::solve(stl_matrix, stl_rhs, viennacl::linalg::cg_tag(1e-6, 20), vcl_jacobi);
//
//
//  /**
//  * <h2>Stabilized BiConjugate Gradient Solver</h2>
//  **/
//  std::cout << "----- BiCGStab Method -----" << std::endl;
//
//  /**
//  * Run BiCGStab for Boost.uBLAS objects. Parameters are the same as for the CG method.
//  **/
//  result = viennacl::linalg::solve(ublas_matrix, rhs, viennacl::linalg::bicgstab_tag());          //without preconditioner
//  result = viennacl::linalg::solve(ublas_matrix, rhs, viennacl::linalg::bicgstab_tag(1e-6, 20), ublas_ilut); //with preconditioner
//  result = viennacl::linalg::solve(ublas_matrix, rhs, viennacl::linalg::bicgstab_tag(1e-6, 20), ublas_jacobi); //with preconditioner
//
//  /**
//  * Run the BiCGStab method for ViennaCL objects.
//  * The results here should be the same as with uBLAS objects (at least up to round-off error).
//  **/
//  vcl_result = viennacl::linalg::solve(vcl_compressed_matrix, vcl_rhs, viennacl::linalg::bicgstab_tag());   //without preconditioner
//  vcl_result = viennacl::linalg::solve(vcl_compressed_matrix, vcl_rhs, viennacl::linalg::bicgstab_tag(1e-6, 20), vcl_ilut); //with preconditioner
//  vcl_result = viennacl::linalg::solve(vcl_compressed_matrix, vcl_rhs, viennacl::linalg::bicgstab_tag(1e-6, 20), vcl_jacobi); //with preconditioner
//
//  /**
//  * Convenience option: Run the BiCGStab method by passing STL types. This will use appropriate ViennaCL objects internally.
//  * You need to include viennacl/compressed_matrix.hpp and viennacl/vector.hpp before viennacl/linalg/bicgstab.hpp for this to work!
//  **/
//  stl_result = viennacl::linalg::solve(stl_matrix, stl_rhs, viennacl::linalg::bicgstab_tag());
//  stl_result = viennacl::linalg::solve(stl_matrix, stl_rhs, viennacl::linalg::bicgstab_tag(1e-6, 20), vcl_ilut);
//  stl_result = viennacl::linalg::solve(stl_matrix, stl_rhs, viennacl::linalg::bicgstab_tag(1e-6, 20), vcl_jacobi);
//
//
//  /**
//  * <h2>GMRES Solver</h2>
//  **/
//  std::cout << "----- GMRES Method -----" << std::endl;
//
//  /**
//  * Run GMRES for Boost.uBLAS objects. Parameters are the same as for the CG method.
//  **/
//  result = viennacl::linalg::solve(ublas_matrix, rhs, viennacl::linalg::gmres_tag());   //without preconditioner
//  result = viennacl::linalg::solve(ublas_matrix, rhs, viennacl::linalg::gmres_tag(1e-6, 20), ublas_ilut);//with preconditioner
//  result = viennacl::linalg::solve(ublas_matrix, rhs, viennacl::linalg::gmres_tag(1e-6, 20), ublas_jacobi);//with preconditioner
//
//  /**
//  * Run the GMRES method for ViennaCL objects.
//  * The results here should be the same as with uBLAS objects (at least up to round-off error).
//  **/
//  vcl_result = viennacl::linalg::solve(vcl_compressed_matrix, vcl_rhs, viennacl::linalg::gmres_tag());   //without preconditioner
//  vcl_result = viennacl::linalg::solve(vcl_compressed_matrix, vcl_rhs, viennacl::linalg::gmres_tag(1e-6, 20), vcl_ilut);//with preconditioner
//  vcl_result = viennacl::linalg::solve(vcl_compressed_matrix, vcl_rhs, viennacl::linalg::gmres_tag(1e-6, 20), vcl_jacobi);//with preconditioner
//
//  /**
//  * Convenience option: Run the GMRES method by passing STL types. This will use appropriate ViennaCL objects internally.
//  * You need to include viennacl/compressed_matrix.hpp and viennacl/vector.hpp before viennacl/linalg/gmres.hpp for this to work!
//  **/
//  stl_result = viennacl::linalg::solve(stl_matrix, stl_rhs, viennacl::linalg::gmres_tag());
//  stl_result = viennacl::linalg::solve(stl_matrix, stl_rhs, viennacl::linalg::gmres_tag(1e-6, 20), vcl_ilut);
//  stl_result = viennacl::linalg::solve(stl_matrix, stl_rhs, viennacl::linalg::gmres_tag(1e-6, 20), vcl_jacobi);
//
//
//  /**
//  *  That's it, the tutorial is completed.
//  **/
//  std::cout << "!!!! TUTORIAL COMPLETED SUCCESSFULLY !!!!" << std::endl;



  return EXIT_SUCCESS;
}

