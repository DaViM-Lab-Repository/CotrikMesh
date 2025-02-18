// Copyright 2013 - Christian Schüller 2013, schuellc@inf.ethz.ch
// Interactive Geometry Lab - ETH Zurich

#pragma once

#ifndef DIRICHLET_LIM_SOLVER_3D_H
#define DIRICHLET_LIM_SOLVER_3D_H

#include "LIMSolver3D.h"

class Dirichlet_LIMSolver3D : public LIMSolver3D
{
public:

  Dirichlet_LIMSolver3D();
  ~Dirichlet_LIMSolver3D();

private:
  
  Eigen::SparseMatrix<double> L;
  
  // implementation of abstract functions of LIMSolver2D
  void debugOutput(std::stringstream& info);
  void prepareProblemData(std::vector<int>& hessRowIdx, std::vector<int>& hessColIdx);
  double computeFunction(const Eigen::Matrix<double,Eigen::Dynamic,1>& x);
  void computeGradient(const Eigen::Matrix<double,Eigen::Dynamic,1>& x, Eigen::Matrix<double,Eigen::Dynamic,1>& grad);
  void computeHessian(const Eigen::Matrix<double,Eigen::Dynamic,1>& x, const Eigen::Matrix<double*,Eigen::Dynamic,1>& hess);
};

#endif