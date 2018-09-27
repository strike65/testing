//
//  Created by VT on 23.08.18.
//  Copyright © 2018 Volker Thieme. All rights reserved.
/*
 Copyright (c) 2017 Volker Thieme
 
 GNU GPL 3+
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, version 3 of the License.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 
 */

import Foundation
import Accelerate.vecLib.LinearAlgebra
import os.log


// matlab Witkovsky

/// Returns the cdf of the noncentral Student t distribution.
/// - Parameter x: x
/// - Parameter df: degrees of freedom
/// - Parameter ncp: noncentrality parameter
/// - Parameter tail: tail
/// - Parameter nSubIntervals: Number of subintervals. Possible values: 32,16,12,10,8,6,4,2. Default is set to 16.
/// - Returns: The tuple (cdf:, error:)
///
/// ### NOTE ###
/// This functions uses an algorithm supposed by Viktor Witkovsky (witkovsky@savba.sk):
/// Witkovsky V. (2013). A Note on Computing Extreme Tail</p>
/// Probabilities of the Noncentral T Distribution with Large</p>
/// Noncentrality Parameter. Working Paper, Institute of Measurement</p>
/// Science, Slovak Academy of Sciences, Bratislava.
///
/// The algorithm uses a Gauss-Kronrod quadrature with an error less than 1e-12 over a wide range of parameters. To reduce the
/// error (in case of extreme parameters) the number of subintervals can be adjusted.
/// Swift Version (C) Volker Thieme 2018
internal func cdfNonCentralTVW<FPT: SSFloatingPoint & Codable>(x: FPT, df: FPT, ncp: FPT, tail: SSCDFTail = .lower, nSubIntervals nSubs: Int = 16) throws -> (cdf: FPT, error: FPT) {
    var cdf: FPT = FPT.nan
    var cdfLower: FPT = 0
    var cdfUpper: FPT = 0
    var todo: Bool = true
    var isLowerTail = todo
    var isLowerGamma = todo
    var ErrBnd: FPT = FPT.nan
    // Special Cases
    if df <= 0 {
        #if os(macOS) || os(iOS)
        if #available(iOS 10, *) {
            os_log("Degrees of freedom are expected to be > 0", log: log_stat, type: .error)
        }
        #endif
        throw SSSwiftyStatsError.init(type: .functionNotDefinedInDomainProvided, file: #file, line: #line, function: #function)
    }
    if x.isInfinite {
        if x < 0 {
            isLowerTail = true
        }
        else {
            isLowerTail = false
        }
        cdf = 0
        todo = false
    }
    if x.isZero {
        if ncp < 0 {
            cdf = FPT.half * erfc1(-ncp / FPT.sqrt2)
            isLowerTail = false
        }
        else if ncp >= 0 {
            cdf = FPT.half * erfc1(ncp / FPT.sqrt2)
            isLowerTail = true
        }
        todo = false
    }
    // transform
    var xx: FPT
    var ncpp: FPT
    var large: Bool
    var neg: Bool
    if todo {
        neg = x < 0
        if neg {
            xx = -x
            ncpp = -ncp
            large = xx >= ncp
            if large {
                isLowerTail = true
                isLowerGamma = true
            }
            else {
                isLowerTail = false
                isLowerGamma = false
            }
        }
        else {
            xx = x
            ncpp = ncp
            large = xx >= ncp
            if large {
                isLowerTail = false
                isLowerGamma = true
            }
            else {
                isLowerTail = true
                isLowerGamma = false
            }
        }
        var result: (cdf: FPT, errBnd: FPT)
        do {
            result = try integrate(x: xx, df: df, ncp: ncpp, isLowerGamma: isLowerGamma, nSubs: 16)
            cdf = result.cdf
            ErrBnd = result.errBnd
        }
        catch {
            throw error
        }
    }
    if isLowerTail {
        cdfLower = cdf
        cdfUpper = 1 - cdf
    }
    else {
        cdfLower = 1 - cdf
        cdfUpper = cdf
    }
    var final: (cdf: FPT, error: FPT)
    switch tail {
    case .lower:
        final.cdf = cdfLower
        final.error = ErrBnd
        return final
    case .upper:
        final.cdf = cdfUpper
        final.error = ErrBnd
        return final
    }
}

fileprivate func integrate<FPT: SSFloatingPoint & Codable>(x: FPT, df: FPT, ncp: FPT, isLowerGamma: Bool, nSubs: Int = 16) throws -> (cdf: FPT, errBnd: FPT) {
    let nf: Int = 1
    let nk: Int = 15
    var subind: Array<Int>;
    var nsub: Int
    switch nSubs {
    case 32: /*    1     2   3     4    5    6      7      8      9      10     11     12     13     14    15*/
        subind = [0,1, 2,3, 4,5, 6,7, 8,9, 10,11, 12,13, 14,15, 16,17, 18,19, 20,21, 22,23, 24,25, 26,27, 28,29]
        nsub = 32
    case 16:
        subind = [2,3,6,7,10,11,14,15,18,19,22,23, 26,27]
        nsub = 16
    case 12:
        subind = [6,7,8,9,14,15,20,21,22,23]
        nsub = 12
    case 10:
        subind = [6,7,12,13,16,17,22,23]
        nsub = 10
    case 8:
        subind = [10,11,14,15,18,19]
        nsub = 8
    case 6:
        subind = [10,11,18,19]
        nsub = 6
    case 4:
        subind = [14,15]
        nsub = 4
    case 2:
        subind = []
        nsub = 2
    default:
        subind = [2,3,6,7,10,11,14,15,18,19,22,23, 26,27]
        nsub = 16
    }
    
    let nz: Int = nsub * nk
    var z: Array<FPT> = Array<FPT>.init(repeating: 0, count: nz)
    var halfw: Array<FPT> = Array<FPT>.init(repeating: 0, count: nsub)
    var cdf: FPT = 0
    var ABC: (A: FPT, B: FPT, MOD: FPT)
    do {
        ABC = try limits(x: makeFP(x), df: makeFP(df), ncp: makeFP(ncp), isLowerGamma: isLowerGamma, nf: nf)
    }
    catch {
        throw error
    }
    if !isLowerGamma {
        cdf = cdfStandardNormalDist(u: ABC.A)
    }
    if isLowerGamma {
        cdf = cdfStandardNormalDist(u: -ABC.B)
    }
    var SUBS: Array<FPT> = [ABC.A, ABC.MOD, ABC.MOD, ABC.B]
    let coeffs: ( XK: [FPT], WK: [FPT], WG: [FPT], G: [Int]) = GKnodes(nsubs: nSubs)
    getSubs(subs: &SUBS, xk: coeffs.XK, subind: subind, z: &z)
    var M: Array<FPT> = Array<FPT>.init()
    var C: Array<FPT> = Array<FPT>.init()

    let half_length: Int = SUBS.count / 2
    for i in stride(from: 0, to: half_length, by: 1) {
        M.append(FPT.half * (SUBS[i + half_length] - SUBS[i]))
        C.append(FPT.half * (SUBS[i + half_length] + SUBS[i]))
    }
    halfw = M
    var T1: Array<FPT> = matMul(a: coeffs.XK, aCols: 1, aRows: coeffs.XK.count, b: M, bCols: M.count, bRows: 1)
    var T2: Array<FPT> = matMul(a: Array<FPT>.init(repeating: 1, count: coeffs.XK.count), aCols: 1, aRows: coeffs.XK.count, b: C, bCols: C.count, bRows: 1)
    let T3: Array<FPT> = matAdd(a: T1, b: T2)
    z = reshape(A: T3, aRows: coeffs.XK.count, aCols: nsub)
    let FV: Array<FPT> = function(z: z, x: x, df: df, ncp: ncp, isLowerGamma: isLowerGamma)
    var Q1: Array<FPT> = Array<FPT>.init(repeating: 0, count: nsub)
    var Q2: Array<FPT> = Array<FPT>.init(repeating: 0, count: nsub)
    let o: Array<FPT> = Array<FPT>.init(repeating: 1, count: nsub)
    var F: Array<FPT> = reshape(A: FV, aRows: halfw.count, aCols: coeffs.WK.count)
    T1 = matMul(a: coeffs.WK, aCols: 1, aRows: nk, b: o, bCols: nsub, bRows: 1)
    
    for i in stride(from: 0, to: T1.count, by: 1) {
        T1[i] *= F[i]
    }
    var S1: Array<FPT> = colSums(A: T1, aRows: nk, aCols: nsub)
    for i in stride(from: 0, to: S1.count, by: 1) {
        Q1[i] = halfw[i] * S1[i]
    }
    T2 = matMul(a: coeffs.WG, aCols: 1, aRows: coeffs.WG.count, b: o, bCols: nsub, bRows: 1)
    F = coeffs.G.map{ F[$0] }
    for i in stride(from: 0, to: F.count, by: 1) {
        T2[i] *= F[i]
    }
    var S2: Array<FPT> = colSums(A: T2, aRows: coeffs.WG.count, aCols: nsub)
    for i in stride(from: 0, to: S2.count, by: 1) {
        Q2[i] = halfw[i] * S2[i]
    }
    cdf = cdf + Q1.reduce(0, +)
    var errs: Array<FPT> = Array<FPT>()
    for i in stride(from: 0, to: Q1.count, by: 1) {
        errs.append(abs(Q1[i] - Q2[i]))
    }
    let errBnd: FPT = errs.reduce(0, +)
    return (cdf: cdf, errBnd: errBnd)
}

fileprivate func function<FPT: SSFloatingPoint & Codable>(z: Array<FPT>, x: FPT, df: FPT, ncp: FPT, isLowerGamma: Bool) -> Array<FPT> {
    let const: FPT = FPT.sqrt2piinv
    var FV: Array<FPT> = Array<FPT>.init(repeating: 0, count: z.count)
    var q: Array<FPT> = (z.map { pow1($0 + ncp, 2) }).map { $0 * (df / (2 * x * x)) }
    var dff: Array<FPT> = Array<FPT>.init(repeating: FPT.half * df, count: z.count)
    var z2: Array<FPT> = z.map{ -FPT.half * $0 * $0 }
    var c: Bool = false
    // gammainc in MATLAB is equal to the regularized Gamma function (P if isLowerGamma, or Q if !isLowerGamma
    if isLowerGamma {
        for i in stride(from: 0, to: z.count, by: 1) {
            FV[i] = gammaNormalizedP(x: q[i], a: dff[i], converged: &c) * exp1(z2[i]) * const
        }
    }
    else {
        for i in stride(from: 0, to: z.count, by: 1) {
            FV[i] = gammaNormalizedQ(x: q[i], a: dff[i], converged: &c) * exp1(z2[i]) * const
        }
    }
    return FV
}



fileprivate func colSums<FPT: FloatingPoint & Codable>(A: Array<FPT>, aRows: Int, aCols: Int) -> Array<FPT> {
    var C: Array<FPT> = Array<FPT>.init()
    let K: Int = aCols
    var temp: FPT = 0
    for k in stride(from: 0, to: K, by: 1) {
        temp = 0
        for i in stride(from: 0, to: aRows, by: 1) {
            temp = temp + A[aCols * i + k]
        }
        C.append(temp)
    }
    return C
}

fileprivate func getSubs<FPT: SSFloatingPoint & Codable>(subs: inout Array<FPT>, xk: Array<FPT>, subind: Array<Int>, z: inout Array<FPT>) {
    var M: Array<FPT> = Array<FPT>.init(repeating: 0, count: 2)
    M[0] = FPT.half * (subs[2] - subs[0])
    M[1] = FPT.half * (subs[3] - subs[1])
    var C: Array<FPT> = Array<FPT>.init(repeating: 0, count: 2)
    C[0] = FPT.half * (subs[2] + subs[0])
    C[1] = FPT.half * (subs[3] + subs[1])
    let T1: Array<FPT> = matMul(a: xk, aCols: 1, aRows: xk.count, b: M, bCols: 2, bRows: 1)
    var T2: Array<FPT> = matMul(a: Array<FPT>.init(repeating: 1, count: xk.count), aCols: 1, aRows: xk.count, b: C, bCols: 2, bRows: 1)
    z = matAdd(a: T1, b: T2)
    T2.removeAll(keepingCapacity: true)
    for i in subind {
        T2.append(z[i])
    }
    var L: Array<FPT> = [subs[0], subs[1]]
    L.append(contentsOf: T2)
    var U: Array<FPT> = T2
    U.append(contentsOf: [subs[2], subs[3]])
    subs = reshape(A: L, aRows: L.count / 2, aCols: 2) + reshape(A: U, aRows: L.count / 2, aCols: 2)
}


func reshape<FPT: FloatingPoint>(A: Array<FPT>, aRows: Int, aCols: Int) -> Array<FPT> {
    var C: Array<FPT> = Array<FPT>.init()
    let K: Int = aCols
    for k in stride(from: 0, to: K, by: 1) {
        for i in stride(from: 0, to: aRows, by: 1) {
            C.append(A[aCols * i + k])
        }
    }
    return C
}


// for limits double should be good
// throws an exception, if a singular matrix was detected
fileprivate func limits<FPT: SSFloatingPoint & Codable>(x: Double, df: Double, ncp: Double, isLowerGamma: Bool, nf: Int) throws -> (A: FPT, B: FPT, MOD: FPT) {
    /* -(log(2) + log(2 Pi) / 2) */
    let const: Double = -1.612085713764618051197561857863794207937
    let logRelTolBnd: Double = log(Double.ulpOfOne)
    /* ≈ quantileNormalDistribution(u: FPT..leastNonzeroMagnitude) */
    var zUppBnd: Double
    var A: Double = 0
    var B: Double = 0
    var MOD: Double = 0
    var incpt: Array<Double> = [1.0,1.0,1.0]
    let tUpp: Double = log(1 / pow(Double.ulpOfOne, 2))
    /* log1(1 / (1 - pow1(Double.ulpOfOne, 2))) */
    let tLow: Double
    zUppBnd = 38.47
    tLow = 4.930380657631323424789330597969121543267e-32
    let NUminus2: Double = max(1, df - 2)
    var ex1: Double
    let ex2: Double = x * x + 2 * df
    let ex3: Double = 4 * df * NUminus2
    let ex4: Double = x * x * (ncp * ncp + 4 * NUminus2)
    MOD = (x * sqrt(ex3 + ex4) - ncp *  ex2) / ( 2 * (x * x + df))
    let dZ: Double = min(Double.half * abs(MOD + ncp), 0.01)
    var dMOD: Array<Double> = Array<Double>.init(arrayLiteral: -dZ, 0, dZ).map { $0 + MOD }
    var q : Array<Double> = dMOD.map { (df * ($0 + ncp)) * (($0 + ncp) / (x * x)) }
    var logfMOD: Array<Double> = Array<Double>.init()
    for i in stride(from: 0, through: 2, by: 1) {
        ex1 = const + 0.5 * (NUminus2 * log1(q[i] / df) + df - q[i] - dMOD[i] * dMOD[i])
        logfMOD.append(ex1)
    }
    let logAbsTolBnd: Double = logfMOD[1] + logRelTolBnd
    var AA: Array<Double> = Array<Double>.init()
    // Column first order!!
    for i in stride(from: 0, to: 3, by: 1) {
        AA.append(dMOD[i] * dMOD[i])
    }
    for i in stride(from: 0, to: 3, by: 1) {
        AA.append(dMOD[i])
    }
    for i in stride(from: 0, to: 3, by: 1) {
        AA.append(incpt[i])
    }
    var abc: [Double] = logfMOD
    // TODO: FIXME0
    var N: __CLPK_integer = 3
    var nrhs: __CLPK_integer = 1
    var lda: __CLPK_integer = 3
    var ldb: __CLPK_integer = 3
    var info: __CLPK_integer = 0
    var ipiv = Array<__CLPK_integer>.init(repeating: 0, count: 3)
    dgesv_(&N, &nrhs, &AA, &lda, &ipiv, &abc, &ldb, &info)
    if info != 0 {
        #if os(macOS) || os(iOS)
        if #available(iOS 10, *) {
            os_log("unable to compute integration limits. A singular matrix was detected", log: log_stat, type: .error)
        }
        #endif
        throw SSSwiftyStatsError.init(type: .functionNotDefinedInDomainProvided, file: #file, line: #line, function: #function)

    }
    let D: Double = sqrt(abc[1] * abc[1] - 4 * abc[0] * (abc[2] - logAbsTolBnd))
    let C: Double = 2.0 * abc[0]
    var A0: Double = max(-zUppBnd, -abc[1] / C + D / C)
    var B0: Double = max(-zUppBnd, min(zUppBnd, -abc[1] / C - D / C))
    let zAbsTolBnd: Double = max(-zUppBnd, sqrt(-1.837877066409345483560659472811235 - 2.0 * logAbsTolBnd))
    var QuantUpp: Double
    var QuantLow: Double
    var zQuantUpp: Double
    var zQuantLow: Double
    var A1: Double
    if isLowerGamma {
        if df > 0 {
            QuantUpp = df + 2 * tUpp + 1.62 * sqrt(df * tUpp) + 0.63012 * sqrt(df) * log(tUpp) - 1.12032 * sqrt(df) - 2.48 * sqrt(tUpp) - 0.65381 * log(tUpp) - 0.22872
        }
        else {
            QuantUpp = 6.739648382445014e+01
        }
        zQuantUpp = sqrt((QuantUpp / df) * x * x) - ncp
        B = min(zAbsTolBnd, zQuantUpp)
        if df > 1e4 && MOD > -zUppBnd && MOD < zUppBnd {
            A0 = MOD - (B - MOD)
        }
        A = max(-ncp, A0)
    }
    else {
        if df > 1 {
            QuantLow = df + 2 * tLow + 1.62 * sqrt(df * tLow) + 0.63012 * sqrt(df) * log(tLow) - 1.12032 * sqrt(df) - 2.48 * sqrt(tLow) - 0.65381 * log(tLow) - 0.22872
            QuantLow = max(0, QuantLow)
        }
        else {
            QuantLow = 0.0
        }
        zQuantLow = sqrt((QuantLow / df) * x * x) - ncp
        A1 = max(-zAbsTolBnd, zQuantLow)
        A1 = max(-ncp, A1)
        A = A1
        if (df > 1e4 && MOD > -zUppBnd && MOD < zUppBnd) {
            B0 = MOD + (MOD - A)
        }
        B = B0
    }
    return (makeFP(A), makeFP(B), makeFP(MOD))
}

fileprivate func GKnodes<FPT: SSFloatingPoint & Codable>(nsubs: Int) -> ( XK: Array<FPT>, WK: Array<FPT>, WG: Array<FPT>, G: [Int]) {
    let nodes: Array<Double> = [
        -0.99145537112081263920685469752632851664204433837034,
        -0.94910791234275852452618968404785126240077093767062,
        -0.86486442335976907278971278864092620121097230707409,
        -0.74153118559939443986386477328078840707414764714139,
        -0.58608723546769113029414483825872959843678075060436,
        -0.4058451513773971669066064120769614633473820140994,
        -0.20778495500789846760068940377324491347978440714517,
        0,
        0.20778495500789846760068940377324491347978440714517,
        0.40584515137739716690660641207696146334738201409937,
        0.58608723546769113029414483825872959843678075060436,
        0.74153118559939443986386477328078840707414764714139,
        0.86486442335976907278971278864092620121097230707409,
        0.94910791234275852452618968404785126240077093767062,
        0.99145537112081263920685469752632851664204433837034
    ]
    let wt: Array<Double> = [
        0.022935322010529224963732008058969591993560811275747,
        0.06309209262997855329070066318920428666507115721155,
        0.10479001032225018383987632254151801744375665421383,
        0.140653259715525918745189590510237920399889757248,
        0.16900472663926790282658342659855028410624490030294,
        0.19035057806478540991325640242101368282607807545536,
        0.20443294007529889241416199923464908471651760418072,
        
        0.2094821410847278280129991748917142636977620802237,
        
        0.20443294007529889241416199923464908471651760418072,
        0.19035057806478540991325640242101368282607807545536,
        0.1690047266392679028265834265985502841062449003029,
        0.140653259715525918745189590510237920399889757248,
        0.1047900103222501838398763225415180174437566542138,
        0.06309209262997855329070066318920428666507115721155,
        0.02293532201052922496373200805896959199356081127575
    ]
    let wt7: Array<Double> = [
        0.12948496616886969327061143267908201832858740225995,
        0.2797053914892766679014677714237795824869250652266,
        0.38183005050511894495036977548897513387836508353386,
        
        0.41795918367346938775510204081632653061224489795918,
        
        0.3818300505051189449503697754889751338783650835339,
        0.2797053914892766679014677714237795824869250652266,
        0.12948496616886969327061143267908201832858740225995
    ]
//    let g: Array<Int> = [2,4,6,8,10,12,14]
    let nodesf: Array<Float> = [
        -0.99145537112081263920685469752632851664204433837034,
        -0.94910791234275852452618968404785126240077093767062,
        -0.86486442335976907278971278864092620121097230707409,
        -0.74153118559939443986386477328078840707414764714139,
        -0.58608723546769113029414483825872959843678075060436,
        -0.4058451513773971669066064120769614633473820140994,
        -0.20778495500789846760068940377324491347978440714517,
        0,
        0.20778495500789846760068940377324491347978440714517,
        0.40584515137739716690660641207696146334738201409937,
        0.58608723546769113029414483825872959843678075060436,
        0.74153118559939443986386477328078840707414764714139,
        0.86486442335976907278971278864092620121097230707409,
        0.94910791234275852452618968404785126240077093767062,
        0.99145537112081263920685469752632851664204433837034
    ]
    let wtf: Array<Float> = [
        0.022935322010529224963732008058969591993560811275747,
        0.06309209262997855329070066318920428666507115721155,
        0.10479001032225018383987632254151801744375665421383,
        0.140653259715525918745189590510237920399889757248,
        0.16900472663926790282658342659855028410624490030294,
        0.19035057806478540991325640242101368282607807545536,
        0.20443294007529889241416199923464908471651760418072,
        
        0.2094821410847278280129991748917142636977620802237,
        
        0.20443294007529889241416199923464908471651760418072,
        0.19035057806478540991325640242101368282607807545536,
        0.1690047266392679028265834265985502841062449003029,
        0.140653259715525918745189590510237920399889757248,
        0.1047900103222501838398763225415180174437566542138,
        0.06309209262997855329070066318920428666507115721155,
        0.02293532201052922496373200805896959199356081127575
    ]
    let wt7f: Array<Float> = [
        0.12948496616886969327061143267908201832858740225995,
        0.2797053914892766679014677714237795824869250652266,
        0.38183005050511894495036977548897513387836508353386,
        
        0.41795918367346938775510204081632653061224489795918,
        
        0.3818300505051189449503697754889751338783650835339,
        0.2797053914892766679014677714237795824869250652266,
        0.12948496616886969327061143267908201832858740225995
    ]
//    let gf: Array<Int> = [2,4,6,8,10,12,14]

    #if arch(i386) || arch(x86_64)
    let nodesl: Array<Float80> = [
        -0.99145537112081263920685469752632851664204433837034,
        -0.94910791234275852452618968404785126240077093767062,
        -0.86486442335976907278971278864092620121097230707409,
        -0.74153118559939443986386477328078840707414764714139,
        -0.58608723546769113029414483825872959843678075060436,
        -0.4058451513773971669066064120769614633473820140994,
        -0.20778495500789846760068940377324491347978440714517,
        0,
        0.20778495500789846760068940377324491347978440714517,
        0.40584515137739716690660641207696146334738201409937,
        0.58608723546769113029414483825872959843678075060436,
        0.74153118559939443986386477328078840707414764714139,
        0.86486442335976907278971278864092620121097230707409,
        0.94910791234275852452618968404785126240077093767062,
        0.99145537112081263920685469752632851664204433837034
    ]
    let wtl: Array<Float80> = [
        0.022935322010529224963732008058969591993560811275747,
        0.06309209262997855329070066318920428666507115721155,
        0.10479001032225018383987632254151801744375665421383,
        0.140653259715525918745189590510237920399889757248,
        0.16900472663926790282658342659855028410624490030294,
        0.19035057806478540991325640242101368282607807545536,
        0.20443294007529889241416199923464908471651760418072,
        
        0.2094821410847278280129991748917142636977620802237,
        
        0.20443294007529889241416199923464908471651760418072,
        0.19035057806478540991325640242101368282607807545536,
        0.1690047266392679028265834265985502841062449003029,
        0.140653259715525918745189590510237920399889757248,
        0.1047900103222501838398763225415180174437566542138,
        0.06309209262997855329070066318920428666507115721155,
        0.02293532201052922496373200805896959199356081127575
    ]
    let wt7l: Array<Float80> = [
        0.12948496616886969327061143267908201832858740225995,
        0.2797053914892766679014677714237795824869250652266,
        0.38183005050511894495036977548897513387836508353386,
        
        0.41795918367346938775510204081632653061224489795918,
        
        0.3818300505051189449503697754889751338783650835339,
        0.2797053914892766679014677714237795824869250652266,
        0.12948496616886969327061143267908201832858740225995
    ]
    #endif
    let G: Array<Int> = [1,3,5,7,9,11,13]
    var g: Array<Int> = Array<Int>()
    for i in G {
        for k in stride(from: 1, through: nsubs, by: 1) {
            g.append(i * nsubs + k - 1)
        }
    }
    switch FPT.self {
        #if arch(i386) || arch(x86_64)
    case is Float80.Type:
        return (XK: nodesl as Array<Float80> as! Array<FPT>, WK: wtl as Array<Float80> as! Array<FPT>, WG: wt7l as Array<Float80> as! Array<FPT>, G: g)
        #endif
    case is Float.Type:
        return (nodesf as Array<Float> as! Array<FPT>, wtf as Array<Float> as! Array<FPT>, wt7f as Array<Float> as! Array<FPT>, G: g)
    case is Double.Type:
        return (nodes as Array<Double> as! Array<FPT>, wt as Array<Double> as! Array<FPT>, wt7 as Array<Double> as! Array<FPT>, G: g)
    default:
        return ([FPT.nan],[FPT.nan],[FPT.nan],[])
    }
}


