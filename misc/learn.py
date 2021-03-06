# -*- coding: utf-8 -*-
"""
Script that lets me play with things I'm learning
"""
from __future__ import absolute_import, division, print_function, unicode_literals


def symbolic_confusion(**known):
    """
    Example:
        >>> known = {'tp': 10, 'fp': 100, 'total': 1000}
        >>> solution = symbolic_confusion(**known)
        >>> print(ub.repr2(solution))
        >>> known = {'tp': 10, 'fp': 100, 'fn': 1}
        >>> solution = symbolic_confusion(**known)
        >>> print(ub.repr2(solution))
        >>> print(ub.repr2(ub.dict_subset(solution, ['fpr']), nl=2))
        >>> known = {'tp': 10, 'fp': 100, 'fn': 1, 'total': 1000}
        >>> solution = symbolic_confusion(**known)
        >>> print(ub.repr2(solution))
        >>> print(ub.repr2(ub.dict_subset(solution, ['fpr']), nl=2))


        >>> known = {'tp': 10, 'pp': 12, 'rp': 15, 'total': 500}
        >>> solution = symbolic_confusion(**known)
        >>> print(ub.repr2(solution))
    """
    import sympy as sym
    all_vars = {}
    def symbols(names, mode):
        if mode == 'nonneg-int':
            flags = {'is_nonnegative': True, 'is_integer': True}
        elif mode == 'nonneg-real':
            flags = {'is_nonnegative': True, 'is_real': True}
        elif mode == 'real':
            flags = {'is_real': True}
        else:
            flags = {}
        out = sym.symbols(names, **flags)
        if isinstance(out, tuple):
            variables = out
        else:
            variables = [out]
        for v in variables:
            all_vars[v.name] = v
        return out

    # Core variables
    (tp, fp, fn, tn) = symbols('tp, fp, fn, tn', 'nonneg-int')
    (rp, pp, rn, pn) = symbols('rp, pp, rn, pn', 'nonneg-int')
    total = symbols('total', 'nonneg-int')

    # Derived varaibles
    tpr, tnr, fnr, fpr = symbols('tpr, tnr, fnr, fpr', 'nonneg-real')
    acc, fdr, for_ = symbols('acc, fdr, for', 'nonneg-real')
    ppv, npv = symbols('ppv, npv', 'nonneg-real')
    mcc, bm, mk, f1 = symbols('mcc, bm, mk, f1', 'real')

    # Aliases
    all_vars['precision'] = ppv
    all_vars['recall'] = tpr

    core_constraints = [
        sym.Eq(total, tp + fp + fn + tn),
        sym.Eq(total, pp + pn),
        sym.Eq(total, rp + rn),

        sym.Eq(rp, tp + fn),
        sym.Eq(rn, tn + fp),

        sym.Eq(pp, tp + fp),
        sym.Eq(pn, tn + fn),
    ]

    #
    # TODO: can we get the functional form of how to compute the other base
    # constants if we specify what we have? (we need 4 dof I think)
    # if False:
    #     sym.solve(core_constraints, [tp, pp, rp, total])
    #     implicit=1)

    derived_constraints = [
        sym.Eq(tpr, tp / (tp + fn)),
        sym.Eq(tnr, tn / (tn + fp)),
        sym.Eq(fnr, fn / (fn + tp)),
        sym.Eq(fpr, tp / (tp + tn)),

        sym.Eq(ppv, tp / (tp + fp)),
        sym.Eq(npv, tn / (tn + fn)),

        sym.Eq(for_, fn / (fn + tn)),
        sym.Eq(fdr,  fp / (fp + tp)),

        sym.Eq(acc,  (tp + tn) / (rp + rn)),
        sym.Eq(f1, 2 * tp / (2 * tp + fp + fn)),
        # using mcc messes up linear equations
        # sym.Eq(mcc, tp * tn - fp * fn / sym.sqrt((tp + fp) * (tp - fn) * (tn + fp) * (tn + fn))),
        sym.Eq(bm, tpr + tnr - 1),
        sym.Eq(mk, ppv + npv - 1),
    ]
    import ubelt as ub

    # Enter as much information as you know
    known_dict = ub.map_keys(all_vars.__getitem__, known)
    known_info = [sym.Eq(k, v) for k, v in known_dict.items()]

    # setup a system of equations representing all constraints
    system = core_constraints + derived_constraints + known_info

    try:
        soln1_ = sym.solve(system)
        soln1 = soln1_[0]
    except:
        soln1 = sym.solve(system, implicit=1)

    solution = {k.name: v for k, v in soln1.items()}

    try:
        solution = {k: v.evalf() for k, v in solution.items()}
    except:
        pass

    return solution


def can_cc_change_mid_iter():
    """
    The connected components can change durring iteration.

    This means when a decision is made that changes the state of the graph, the
    current iterable may no longer be valid. For example, if we are trying to
    find potential negative redundancies, and we loop over all combinations of
    non-neg-redundant PCCs, if we ever decide that two of these PCCs are in
    fact the same, then then candidate edges generated in the future may be
    within the same PCC.

    To make this concrete say we have PCCs: 1, 2, and 3.
    We iterate over all combinations of these PCCs.

        >>> pccs = [1, 2, 3]
        >>> for cc1, cc2 in it.combinations(pccs, 2):
        ...     print('compare PCCs {} and {}'.format(cc1, cc2))
        compare PCCs 1 and 2
        compare PCCs 1 and 3
        compare PCCs 2 and 3

    If we decide that an edge between PCC 1 and 2 is positive, and an edge
    between PCC 1 and 3 is positive then they the entire graph will be merged
    into the same PCC. However, when we next compare 2 and 3 the "negative
    redundant" suggestion will have to be within the same PCC.

    Currently the code assumes that the PCCs we test for negative redundancy
    will be disjoint. This iteration pattern violates this assumption.

    However, iterators are how we achieve a fair amount of efficiency in the
    code. Alternative strategires are to:
        1. Restart neg-redundancy finding whenever we add a positive edge.
        2. Precompute all the edges we will suggest before we allow the user to
           make a decision, then the assumptions made wont be violated, but the
           reviewer will end up reviewing edges within a PCC in negative
           redundancy mode. Also, the amount of precomputation is enormous.
        3. Compute neg-redundancy in chunks

    Therefore, we need to modify code to not assume that the pccs we will tests
    for neg-redun will be disjoint.


    """
    import networkx as nx
    g = nx.Graph()
    g.add_nodes_from([1, 2, 3, 4, 5])

    for cc in nx.connected_components(g):
        print('cc = {!r}'.format(cc))

    for cc in nx.connected_components(g):
        g.add_edge(1, 5)
        g.add_edge(2, 5)
        print('cc = {!r}'.format(cc))


def orient_bbox():
    import sympy as sym
    sin, cos = sym.sin, sym.cos
    θ = sym.symbols('θ')
    cx, cy = sym.symbols('cx, cy')
    w, h = sym.symbols('w, h')
    R = sym.Matrix([
        [cos(θ), -sin(θ), 0],
        [sin(θ),  cos(θ), 0],
        [0, 0, 1]
    ])

    T = sym.Matrix([
        [ 1,  0, cx],
        [ 0,  1, cy],
        [0, 0, 1]
    ])

    # assuming the bbox is at the origin, the top right corner is half the
    # width and height
    half_size = sym.Matrix([w / 2, h / 2, 1])

    # rotate this corner point and then translate it to the center of world
    # coords

    top_right = half_size
    top_left = half_size.multiply_elementwise(sym.Matrix([-1, 1, 1]))
    bot_left = half_size.multiply_elementwise(sym.Matrix([-1, -1, 1]))
    bot_right = half_size.multiply_elementwise(sym.Matrix([1, -1, 1]))

    T.dot(R.dot(top_right))

    print(T.dot(R.dot(top_right)))
    print(T.dot(R.dot(top_left)))
    print(T.dot(R.dot(bot_left)))
    print(T.dot(R.dot(bot_right)))

    # [cx - h*sin(θ)/2 + w*cos(θ)/2, cy + h*cos(θ)/2 + w*sin(θ)/2, 1]
    # [cx - h*sin(θ)/2 - w*cos(θ)/2, cy + h*cos(θ)/2 - w*sin(θ)/2, 1]
    # [cx + h*sin(θ)/2 - w*cos(θ)/2, cy - h*cos(θ)/2 - w*sin(θ)/2, 1]
    # [cx + h*sin(θ)/2 + w*cos(θ)/2, cy - h*cos(θ)/2 + w*sin(θ)/2, 1]


def pandas_reorder(df, part):
    import utool as ut
    df = df.reindex_axis(ut.partial_order(df.columns, part), axis=1)


def pass_futures_between_process():
    from concurrent.futures import ProcessPoolExecutor, ThreadPoolExecutor
    import time

    def job1():
        try:
            ex2 = ThreadPoolExecutor()
            time.sleep(2)
            f2 = ex2.submit(job2)
        finally:
            ex2.shutdown(wait=False)
        return f2

    def job2():
        time.sleep(2)
        return 'done'

    try:
        ex1 = ProcessPoolExecutor()
        f1 = ex1.submit(job1)
    finally:
        ex1.shutdown(wait=False)

    print('f1 = {!r}'.format(f1))
    f2 = f1.result()
    print('f1 = {!r}'.format(f1))
    print('f2 = {!r}'.format(f2))


def pandas_merge():
    import pandas as pd
    x = pd.DataFrame.from_dict(
        {'a': [41, 1], 'b': [2, 1], 'e': [4, 1]}, orient='index')
    y = pd.DataFrame.from_dict(
        {'a': [1, 0], 'b': [2, 0], 'c': [3, 0], 'd': [4, 0]}, orient='index')
    x = x.rename(columns={0: 'foo', 1: 'bar'})
    y = y.rename(columns={0: 'foo', 1: 'bar'})
    new = pd.merge(x, y, how='outer', on=x.columns.tolist(),
                   left_index=True, right_index=True)
    print('new_xy = %r' % (new,))
    new = pd.merge(y, x, how='outer', on=x.columns.tolist(),
                   left_index=True, right_index=True)
    print('new_yx = %r' % (new,))

    a = pd.DataFrame.from_dict(
        {'a': [41, 1], 'b': [2, 1], 'e': [4, 1]}, orient='index')
    b = pd.DataFrame.from_dict(
        {'x': [1, 0], 'y': [2, 0], 'z': [3, 0], 'q': [4, 0]}, orient='index')
    a = a.rename(columns={0: 'foo', 1: 'bar'})

    b = b.rename(columns={0: 'foo', 1: 'bar'})
    new = pd.merge(a, b, how='outer', on=x.columns.tolist(),
                   left_index=True, right_index=True)
    print('new_ab = %r' % (new,))
    new = pd.merge(a, b, how='outer', on=x.columns.tolist(),
                   left_index=True, right_index=True)
    print('new_ba = %r' % (new,))

    import ubelt
    for timer in ubelt.Timerit(10):
        with timer:
            new = pd.merge(a, b, how='outer', on=x.columns.tolist(),
                           left_index=True, right_index=True)
    import ubelt
    for timer in ubelt.Timerit(10):
        with timer:
            new = pd.merge(a, b, how='outer', on=x.columns.tolist(),
                           left_index=True, right_index=True, copy=False)


def iters_until_threshold():
    """
    How many iterations of ewma until you hit the poisson / biniomal threshold

    This establishes a principled way to choose the threshold for the refresh
    criterion in my thesis. There are paramters --- moving parts --- that we
    need to work with: `a` the patience, `s` the span, and `mu` our ewma.

    `s` is a span paramter indicating how far we look back.

    `mu` is the average number of label-changing reviews in roughly the last
    `s` manual decisions.

    These numbers are used to estimate the probability that any of the next `a`
    manual decisions will be label-chanigng. When that probability falls below
    a threshold we terminate. The goal is to choose `a`, `s`, and the threshold
    `t`, such that the probability will fall below the threshold after a maximum
    of `a` consecutive non-label-chaning reviews. IE we want to tie the patience
    paramter (how far we look ahead) to how far we actually are willing to go.
    """
    import numpy as np
    import utool as ut
    import sympy as sym
    i = sym.symbols('i', integer=True, nonnegative=True, finite=True)
    # mu_i = sym.symbols('mu_i', integer=True, nonnegative=True, finite=True)
    s = sym.symbols('s', integer=True, nonnegative=True, finite=True)  # NOQA
    thresh = sym.symbols('tau', real=True, nonnegative=True, finite=True)  # NOQA
    alpha = sym.symbols('alpha', real=True, nonnegative=True, finite=True)  # NOQA
    c_alpha = sym.symbols('c_alpha', real=True, nonnegative=True, finite=True)
    # patience
    a = sym.symbols('a', real=True, nonnegative=True, finite=True)

    available_subs = {
        a: 20,
        s: a,
        alpha: 2 / (s + 1),
        c_alpha: (1 - alpha),
    }

    def dosubs(expr, d=available_subs):
        """ recursive expression substitution """
        expr1 = expr.subs(d)
        if expr == expr1:
            return expr1
        else:
            return dosubs(expr1, d=d)

    # mu is either the support for the poisson distribution
    # or is is the p in the binomial distribution
    # It is updated at timestep i based on ewma, assuming each incoming responce is 0
    mu_0 = 1.0
    mu_i = c_alpha ** i

    # Estimate probability that any event will happen in the next `a` reviews
    # at time `i`.
    poisson_i = 1 - sym.exp(-mu_i * a)
    binom_i = 1 - (1 - mu_i) ** a

    # Expand probabilities to be a function of i, s, and a
    part = ut.delete_dict_keys(available_subs.copy(), [a, s])
    mu_i = dosubs(mu_i, d=part)
    poisson_i = dosubs(poisson_i, d=part)
    binom_i = dosubs(binom_i, d=part)

    if True:
        # ewma of mu at time i if review is always not label-changing (meaningful)
        mu_1 = c_alpha * mu_0  # NOQA
        mu_2 = c_alpha * mu_1  # NOQA

    if True:
        i_vals = np.arange(0, 100)
        mu_vals = np.array([dosubs(mu_i).subs({i: i_}).evalf() for i_ in i_vals])  # NOQA
        binom_vals = np.array([dosubs(binom_i).subs({i: i_}).evalf() for i_ in i_vals])  # NOQA
        poisson_vals = np.array([dosubs(poisson_i).subs({i: i_}).evalf() for i_ in i_vals])  # NOQA

        # Find how many iters it actually takes my expt to terminate
        thesis_draft_thresh = np.exp(-2)
        np.where(mu_vals < thesis_draft_thresh)[0]
        np.where(binom_vals < thesis_draft_thresh)[0]
        np.where(poisson_vals < thesis_draft_thresh)[0]

    sym.pprint(sym.simplify(mu_i))
    sym.pprint(sym.simplify(binom_i))
    sym.pprint(sym.simplify(poisson_i))

    # Find the thresholds that force termination after `a` reviews have passed
    # do this by setting i=a
    poisson_thresh = poisson_i.subs({i: a})
    binom_thresh = binom_i.subs({i: a})

    print('Poisson thresh')
    print(sym.latex(sym.Eq(thresh, poisson_thresh)))
    print(sym.latex(sym.Eq(thresh, sym.simplify(poisson_thresh))))

    poisson_thresh.subs({a: 115, s: 30}).evalf()

    sym.pprint(sym.Eq(thresh, poisson_thresh))
    sym.pprint(sym.Eq(thresh, sym.simplify(poisson_thresh)))

    print('Binomial thresh')
    sym.pprint(sym.simplify(binom_thresh))

    sym.pprint(sym.simplify(poisson_thresh.subs({s: a})))

    def taud(coeff):
        return coeff * 360

    if 'poisson_cache' not in vars():
        poisson_cache = {}
        binom_cache = {}

    S, A = np.meshgrid(np.arange(1, 150, 1), np.arange(0, 150, 1))

    import plottool as pt
    SA_coords = list(zip(S.ravel(), A.ravel()))
    for sval, aval in ut.ProgIter(SA_coords):
        if (sval, aval) not in poisson_cache:
            poisson_cache[(sval, aval)] = float(poisson_thresh.subs({a: aval, s: sval}).evalf())
    poisson_zdata = np.array(
        [poisson_cache[(sval, aval)] for sval, aval in SA_coords]).reshape(A.shape)
    fig = pt.figure(fnum=1, doclf=True)
    pt.gca().set_axis_off()
    pt.plot_surface3d(S, A, poisson_zdata, xlabel='s', ylabel='a',
                      rstride=3, cstride=3,
                      zlabel='poisson', mode='wire', contour=True,
                      title='poisson3d')
    pt.gca().set_zlim(0, 1)
    pt.gca().view_init(elev=taud(1 / 16), azim=taud(5 / 8))
    fig.set_size_inches(10, 6)
    fig.savefig('a-s-t-poisson3d.png', dpi=300, bbox_inches=pt.extract_axes_extents(fig, combine=True))

    for sval, aval in ut.ProgIter(SA_coords):
        if (sval, aval) not in binom_cache:
            binom_cache[(sval, aval)] = float(binom_thresh.subs({a: aval, s: sval}).evalf())
    binom_zdata = np.array(
        [binom_cache[(sval, aval)] for sval, aval in SA_coords]).reshape(A.shape)
    fig = pt.figure(fnum=2, doclf=True)
    pt.gca().set_axis_off()
    pt.plot_surface3d(S, A, binom_zdata, xlabel='s', ylabel='a',
                      rstride=3, cstride=3,
                      zlabel='binom', mode='wire', contour=True,
                      title='binom3d')
    pt.gca().set_zlim(0, 1)
    pt.gca().view_init(elev=taud(1 / 16), azim=taud(5 / 8))
    fig.set_size_inches(10, 6)
    fig.savefig('a-s-t-binom3d.png', dpi=300, bbox_inches=pt.extract_axes_extents(fig, combine=True))

    # Find point on the surface that achieves a reasonable threshold

    # Sympy can't solve this
    # sym.solve(sym.Eq(binom_thresh.subs({s: 50}), .05))
    # sym.solve(sym.Eq(poisson_thresh.subs({s: 50}), .05))
    # Find a numerical solution
    def solve_numeric(expr, target, solve_for, fixed={}, method=None, bounds=None):
        """
        Args:
            expr (Expr): symbolic expression
            target (float): numberic value
            solve_for (sympy.Symbol): The symbol you care about
            fixed (dict): fixed values of the symbol

        solve_numeric(poisson_thresh, .05, {s: 30}, method=None)
        solve_numeric(poisson_thresh, .05, {s: 30}, method='Nelder-Mead')
        solve_numeric(poisson_thresh, .05, {s: 30}, method='BFGS')
        """
        import scipy.optimize
        # Find the symbol you want to solve for
        want_symbols = expr.free_symbols - set(fixed.keys())
        # TODO: can probably extend this to multiple params
        assert len(want_symbols) == 1, 'specify all but one var'
        assert solve_for == list(want_symbols)[0]
        fixed_expr = expr.subs(fixed)
        def func(a1):
            expr_value = float(fixed_expr.subs({solve_for: a1}).evalf())
            return (expr_value - target) ** 2
        if not fixed:
            a1 = 0
        else:
            a1 = list(fixed.values())[0]
        # if method is None:
        #     method = 'Nelder-Mead'
        #     method = 'Newton-CG'
        #     method = 'BFGS'
        result = scipy.optimize.minimize(func, x0=a1, method=method, bounds=bounds)
        if not result.success:
            print('\n')
            print(result)
            print('\n')
        return result

    # Numeric measurments of thie line

    thresh_vals = [.001, .01, .05, .1, .135]
    svals = np.arange(1, 100)

    target_poisson_plots = {}
    for target in ut.ProgIter(thresh_vals, bs=False, freq=1):
        poisson_avals = []
        for sval in ut.ProgIter(svals, 'poisson', freq=1):
            expr = poisson_thresh
            fixed = {s: sval}
            want = a
            aval = solve_numeric(expr, target, want, fixed,
                                 method='Nelder-Mead').x[0]
            poisson_avals.append(aval)
        target_poisson_plots[target] = (svals, poisson_avals)

    fig = pt.figure(fnum=3)
    for target, dat in target_poisson_plots.items():
        pt.plt.plot(*dat, label='prob={}'.format(target))
    pt.gca().set_xlabel('s')
    pt.gca().set_ylabel('a')
    pt.legend()
    pt.gca().set_title('poisson')
    fig.set_size_inches(5, 3)
    fig.savefig('a-vs-s-poisson.png', dpi=300, bbox_inches=pt.extract_axes_extents(fig, combine=True))

    target_binom_plots = {}
    for target in ut.ProgIter(thresh_vals, bs=False, freq=1):
        binom_avals = []
        for sval in ut.ProgIter(svals, 'binom', freq=1):
            aval = solve_numeric(binom_thresh, target, a, {s: sval}, method='Nelder-Mead').x[0]
            binom_avals.append(aval)
        target_binom_plots[target] = (svals, binom_avals)

    fig = pt.figure(fnum=4)
    for target, dat in target_binom_plots.items():
        pt.plt.plot(*dat, label='prob={}'.format(target))
    pt.gca().set_xlabel('s')
    pt.gca().set_ylabel('a')
    pt.legend()
    pt.gca().set_title('binom')
    fig.set_size_inches(5, 3)
    fig.savefig('a-vs-s-binom.png', dpi=300, bbox_inches=pt.extract_axes_extents(fig, combine=True))

    # ----
    if True:

        fig = pt.figure(fnum=5, doclf=True)
        s_vals = [1, 2, 3, 10, 20, 30, 40, 50]
        for sval in s_vals:
            pp = poisson_thresh.subs({s: sval})

            a_vals = np.arange(0, 200)
            pp_vals = np.array([float(pp.subs({a: aval}).evalf()) for aval in a_vals])  # NOQA

            pt.plot(a_vals, pp_vals, label='s=%r' % (sval,))
        pt.legend()
        pt.gca().set_xlabel('a')
        pt.gca().set_ylabel('poisson prob after a reviews')
        fig.set_size_inches(5, 3)
        fig.savefig('a-vs-thresh-poisson.png', dpi=300, bbox_inches=pt.extract_axes_extents(fig, combine=True))

        fig = pt.figure(fnum=6, doclf=True)
        s_vals = [1, 2, 3, 10, 20, 30, 40, 50]
        for sval in s_vals:
            pp = binom_thresh.subs({s: sval})
            a_vals = np.arange(0, 200)
            pp_vals = np.array([float(pp.subs({a: aval}).evalf()) for aval in a_vals])  # NOQA
            pt.plot(a_vals, pp_vals, label='s=%r' % (sval,))
        pt.legend()
        pt.gca().set_xlabel('a')
        pt.gca().set_ylabel('binom prob after a reviews')
        fig.set_size_inches(5, 3)
        fig.savefig('a-vs-thresh-binom.png', dpi=300, bbox_inches=pt.extract_axes_extents(fig, combine=True))

        # -------

        fig = pt.figure(fnum=5, doclf=True)
        a_vals = [1, 2, 3, 10, 20, 30, 40, 50]
        for aval in a_vals:
            pp = poisson_thresh.subs({a: aval})
            s_vals = np.arange(1, 200)
            pp_vals = np.array([float(pp.subs({s: sval}).evalf()) for sval in s_vals])  # NOQA
            pt.plot(s_vals, pp_vals, label='a=%r' % (aval,))
        pt.legend()
        pt.gca().set_xlabel('s')
        pt.gca().set_ylabel('poisson prob')
        fig.set_size_inches(5, 3)
        fig.savefig('s-vs-thresh-poisson.png', dpi=300, bbox_inches=pt.extract_axes_extents(fig, combine=True))

        fig = pt.figure(fnum=5, doclf=True)
        a_vals = [1, 2, 3, 10, 20, 30, 40, 50]
        for aval in a_vals:
            pp = binom_thresh.subs({a: aval})
            s_vals = np.arange(1, 200)
            pp_vals = np.array([float(pp.subs({s: sval}).evalf()) for sval in s_vals])  # NOQA
            pt.plot(s_vals, pp_vals, label='a=%r' % (aval,))
        pt.legend()
        pt.gca().set_xlabel('s')
        pt.gca().set_ylabel('binom prob')
        fig.set_size_inches(5, 3)
        fig.savefig('s-vs-thresh-binom.png', dpi=300, bbox_inches=pt.extract_axes_extents(fig, combine=True))

    #---------------------
    # Plot out a table

    mu_i.subs({s: 75, a: 75}).evalf()
    poisson_thresh.subs({s: 75, a: 75}).evalf()

    sval = 50
    for target, dat in target_poisson_plots.items():
        slope = np.median(np.diff(dat[1]))
        aval = int(np.ceil(sval * slope))
        thresh = float(poisson_thresh.subs({s: sval, a: aval}).evalf())
        print('aval={}, sval={}, thresh={}, target={}'.format(aval, sval, thresh, target))

    for target, dat in target_binom_plots.items():
        slope = np.median(np.diff(dat[1]))
        aval = int(np.ceil(sval * slope))
        pass

    # def find_binom_numerical(**kwargs):
    #     def binom_func(aval, sval):
    #         return float(binom_thresh.subs({s: sval, a: aval}).evalf())
    #     def make_minimizer(target, **kwargs):
    #         binom_partial = ut.partial(binom_func, **kwargs)
    #         def min_binom(*args):
    #             return (target - binom_partial(*args)) ** 2
    #         return min_binom
    #     import scipy.optimize
    #     assert bool('aval' in kwargs) != bool('sval' in kwargs), 'specify only one'
    #     x0 = kwargs.get('aval', kwargs.get('sval'))
    #     func = make_minimizer(**kwargs)
    #     result = scipy.optimize.minimize(func, x0=x0)
    #     if not result.success:
    #         print('\n')
    #         print(result)
    #         print('\n')
    #     return result.x[0]

    # def find_poisson_numerical(**kwargs):
    #     def poisson_func(aval, sval):
    #         return float(poisson_thresh.subs({s: sval, a: aval}).evalf())
    #     def make_minimizer(target, **kwargs):
    #         poisson_partial = ut.partial(poisson_func, **kwargs)
    #         def min_poisson(*args):
    #             return (target - poisson_partial(*args)) ** 2
    #         return min_poisson
    #     import scipy.optimize
    #     assert bool('aval' in kwargs) != bool('sval' in kwargs), 'specify only one'
    #     x0 = kwargs.get('aval', kwargs.get('sval'))
    #     func = make_minimizer(**kwargs)
    #     result = scipy.optimize.minimize(func, x0=x0)
    #     if not result.success:
    #         print('\n')
    #         print(result)
    #         print('\n')
    #     return result.x[0]


def ewma():
    import plottool as pt
    import ubelt as ub
    import numpy as np
    pt.qtensure()

    # Investigate the span parameter
    span = 20
    alpha = 2 / (span + 1)

    # how long does it take for the estimation to hit 0?
    # (ie, it no longer cares about the initial 1?)
    # about 93 iterations to get to 1e-4
    # about 47 iterations to get to 1e-2
    # about 24 iterations to get to 1e-1
    # 20 iterations goes to .135
    data = (
        [1] +
        [0] * 20 + [1] * 40 +
        [0] * 20 + [1] * 50 +
        [0] * 20 + [1] * 60 +
        [0] * 20 + [1] * 165 +
        [0] * 20 +
        [0]
    )
    mave = []

    iter_ = iter(data)
    current = next(iter_)
    mave += [current]
    for x in iter_:
        current = (alpha * x) + (1 - alpha) * current
        mave += [current]

    if False:
        pt.figure(fnum=1, doclf=True)
        pt.plot(data)
        pt.plot(mave)

    np.where(np.array(mave) < 1e-1)

    import sympy as sym

    # span, alpha, n = sym.symbols('span, alpha, n')
    n = sym.symbols('n', integer=True, nonnegative=True, finite=True)
    span = sym.symbols('span', integer=True, nonnegative=True, finite=True)
    thresh = sym.symbols('thresh', real=True, nonnegative=True, finite=True)
    # alpha = 2 / (span + 1)

    a, b, c = sym.symbols('a, b, c', real=True, nonnegative=True, finite=True)
    sym.solve(sym.Eq(b ** a, c), a)

    current = 1
    x = 0
    steps = []
    for _ in range(10):
        current = (alpha * x) + (1 - alpha) * current
        steps.append(current)

    alpha = sym.symbols('alpha', real=True, nonnegative=True, finite=True)
    base = sym.symbols('base', real=True, finite=True)
    alpha = 2 / (span + 1)
    thresh_expr = (1 - alpha) ** n
    thresthresh_exprh_expr = base ** n
    n_expr = sym.ceiling(sym.log(thresh) / sym.log(1 -  2 / (span + 1)))

    sym.pprint(sym.simplify(thresh_expr))
    sym.pprint(sym.simplify(n_expr))
    print(sym.latex(sym.simplify(n_expr)))

    # def calc_n2(span, thresh):
    #     return np.log(thresh) / np.log(1 - 2 / (span + 1))

    def calc_n(span, thresh):
        return np.log(thresh) / np.log((span - 1) / (span + 1))

    def calc_thresh_val(n, span):
        alpha = 2 / (span + 1)
        return (1 - alpha) ** n

    span = np.arange(2, 200)
    n_frac = calc_n(span, thresh=.5)
    n = np.ceil(n_frac)
    calc_thresh_val(n, span)

    pt.figure(fnum=1, doclf=True)
    ydatas = ut.odict([
        ('thresh=%f' % thresh, np.ceil(calc_n(span, thresh=thresh)))
        for thresh in [1e-3, .01, .1, .2, .3, .4, .5]

    ])
    pt.multi_plot(span, ydatas,
                  xlabel='span',
                  ylabel='n iters to acheive thresh',
                  marker='',
                  # num_xticks=len(span),
                  fnum=1)
    pt.gca().set_aspect('equal')


    def both_sides(eqn, func):
        return sym.Eq(func(eqn.lhs), func(eqn.rhs))

    eqn = sym.Eq(thresh_expr, thresh)
    n_expr = sym.solve(eqn, n)[0].subs(base, (1 - alpha)).subs(alpha, (2 / (span + 1)))

    eqn = both_sides(eqn, lambda x: sym.log(x, (1 - alpha)))
    lhs = eqn.lhs

    from sympy.solvers.inequalities import solve_univariate_inequality

    def eval_expr(span_value, n_value):
        return np.array([thresh_expr.subs(span, span_value).subs(n, n_)
                         for n_ in n_value], dtype=np.float)

    eval_expr(20, np.arange(20))

    def linear(x, a, b):
        return a * x + b

    def sigmoidal_4pl(x, a, b, c, d):
        return d + (a - d) / (1 + (x / c) ** b)

    def exponential(x, a, b, c):
        return a + b * np.exp(-c * x)

    import scipy.optimize

    # Determine how to choose span, such that you get to .01 from 1
    # in n timesteps
    thresh_to_span_to_n = []
    thresh_to_n_to_span = []
    for thresh_value in ub.ProgIter([.0001, .001, .01, .1, .2, .3, .4, .5]):
        print('')
        test_vals = sorted([2, 3, 4, 5, 6])
        n_to_span = []
        for n_value in ub.ProgIter(test_vals):
            # In n iterations I want to choose a span that the expression go
            # less than a threshold
            constraint = thresh_expr.subs(n, n_value) < thresh_value
            solution = solve_univariate_inequality(constraint, span)
            try:
                lowbound = np.ceil(float(solution.args[0].lhs))
                highbound = np.floor(float(solution.args[1].rhs))
                assert lowbound <= highbound
                span_value = lowbound
            except AttributeError:
                span_value = np.floor(float(solution.rhs))
            n_to_span.append((n_value, span_value))

        # Given a threshold, find a minimum number of steps
        # that brings you up to that threshold given a span
        test_vals = sorted(set(list(range(2, 1000, 50)) + [2, 3, 4, 5, 6]))
        span_to_n = []
        for span_value in ub.ProgIter(test_vals):
            constraint = thresh_expr.subs(span, span_value) < thresh_value
            solution = solve_univariate_inequality(constraint, n)
            n_value = solution.lhs
            span_to_n.append((span_value, n_value))

        thresh_to_n_to_span.append((thresh_value, n_to_span))
        thresh_to_span_to_n.append((thresh_value, span_to_n))

    thresh_to_params = []
    for thresh_value, span_to_n in thresh_to_span_to_n:
        xdata, ydata = [np.array(_, dtype=np.float) for _ in zip(*span_to_n)]

        p0 = (1 / np.diff((ydata - ydata[0])[1:]).mean(), ydata[0])
        func = linear
        popt, pcov = scipy.optimize.curve_fit(func, xdata, ydata, p0)
        # popt, pcov = scipy.optimize.curve_fit(exponential, xdata, ydata)

        if False:
            yhat = func(xdata, *popt)
            pt.figure(fnum=1, doclf=True)
            pt.plot(xdata, ydata, label='measured')
            pt.plot(xdata, yhat, label='predicteed')
            pt.legend()
        # slope = np.diff(ydata).mean()
        # pt.plot(d)
        thresh_to_params.append((thresh_value, popt))

    # pt.plt.plot(*zip(*thresh_to_slope), 'x-')

    # for thresh_value=.01, we get a rough line with slop ~2.302,
    # for thresh_value=.5, we get a line with slop ~34.66

    # if we want to get to 0 in n timesteps, with a thresh_value of
    # choose span=f(thresh_value) * (n + 2))
    # f is some inverse exponential

    # 0.0001, 460.551314197147
    # 0.001, 345.413485647860,
    # 0.01, 230.275657098573,
    # 0.1, 115.137828549287,
    # 0.2, 80.4778885203347,
    # 0.3, 60.2031233261536,
    # 0.4, 45.8179484913827,
    # 0.5, 34.6599400289520

    # Seems to be 4PL symetrical sigmoid
    # f(x) = -66500.85 + (66515.88 - -66500.85) / (1 + (x/0.8604672)^0.001503716)
    # f(x) = -66500.85 + (66515.88 - -66500.85)/(1 + (x/0.8604672)^0.001503716)

    def f(x):
        return -66500.85 + (66515.88 - -66500.85) / (1 + (x/0.8604672) ** 0.001503716)
        # return (10000 * (-6.65 + (13.3015) / (1 + (x/0.86) ** 0.00150)))

    # f(.5) * (n - 1)

    # f(
    solve_rational_inequalities(thresh_expr < .01, n)


def mean_decrease_impurity():
    '''
    N = num training examples

    t = node
    t.num = number of training samples at t

    t.p = t.num / N  = fraction of training samples at t

    p_L = t.left.num / t.num
    p_R = t.right.num / t.num

    i(t) = impurity / entropy class labels at the node

    ∆i(t) = impurity decrease at the node
    ∆i(t) = i(t) − p_L * i(tL) − p_R * i(tR)
    t.∆i t.delta_i = ∆i(t)

    # importance of feature dimension j in tree m
    # This is the weighted impurity decrease of all nodes using that feature in m
    MDI(j, m) = sum(p(t) * ∆i(s, t) for t in m if t.feature = j)
    MDI(j, m) = sum(t.p * t.∆i for t in m if t.feature = j)

    MDI(feat, tree) = sum(node.p * node.delta_i for node in tree if node.feature = feat)

    '''
    import sympy as sym
    n, nL, nR, N, i, iR, iL = sym.symbols('n, n_L, n_R, N, i, iR, iL')

    p = n / N
    pL = nL / N
    pR = nR / N

    wL = nL / n
    wR = nL / n

    delta_i1 = i - (wL * iL + wR * iR)
    delta_i2 = p * i - (pL * iL + pR * iR)

    print('Real Delta ∆i(t)')
    sym.pprint(sym.simplify(delta_i1))

    print('')
    print('Alt Delta ∆i(t)')
    sym.pprint(delta_i2 * N / n)
    sym.pprint(sym.simplify(delta_i2 * N / n))

    sym.pprint(sym.simplify((p * i - (pL * iL + pR * iR)) / p))


def chunked_search():
    """
    Computational complexity of building one kd-tree and searching vs building
    many and searching.


    --------------------------------
    Normal Running Time:
        Indexing:
            D⋅log(D⋅p)
        Query:
            Q⋅log(D⋅p)
    --------------------------------

    --------------------------------
    Chunked Running Time:
        Indexing:
                 ⎛D⋅p⎞
            D⋅log⎜───⎟
                 ⎝ C ⎠
        Query:
                   ⎛D⋅p⎞
            C⋅Q⋅log⎜───⎟
                   ⎝ C ⎠
    --------------------------------

    Conclusion: chunking provides a tradeoff in running time.
    It can make indexing, faster, but it makes query-time slower.  However, it
    does allow for partial database search, which can speed up response time of
    queries. It can also short-circuit itself once a match has been found.
    """
    import sympy as sym
    import utool as ut
    ceil = sym.ceiling
    ceil = ut.identity
    log = sym.log

    #
    # ====================
    # Define basic symbols
    # ====================

    # Number of database and query annotations
    n_dannots, n_qannots = sym.symbols('D, Q')

    # Average number of descriptors per annotation
    n_vecs_per_annot = sym.symbols('p')

    # Size of the shortlist to rerank
    n_rr = sym.symbols('L')

    # The number of chunks
    C = sym.symbols('C')

    #
    # ===============================================
    # Define helper functions and intermediate values
    # ===============================================
    n_dvecs = n_vecs_per_annot * n_dannots

    # Could compute the maximum average matches something gets
    # but for now just hack it
    fmatch = sym.Function('fmatch')
    n_fmatches = fmatch(n_vecs_per_annot)

    # The complexity of spatial verification is roughly that of SVD
    # SV_fn = lambda N: N ** 3  # NOQA
    SV_fn = sym.Function('SV')
    SV = SV_fn(n_fmatches)

    class KDTree(object):
        # A bit of a simplification
        n_trees = sym.symbols('T')
        params = {n_trees}

        @classmethod
        def build(self, N):
            return N * log(N) * self.n_trees

        @classmethod
        def search(self, N):
            # This is average case
            return log(N) * self.n_trees

    Indexer = KDTree

    def sort(N):
        return N * log(N)

    #
    # ========================
    # Define normal complexity
    # ========================

    # The computational complexity of the normal hotspotter pipeline
    normal = {}
    normal['indexing'] = Indexer.build(n_dvecs)
    normal['search'] = n_vecs_per_annot * Indexer.search(n_dvecs)
    normal['rerank'] = (SV * n_rr)
    normal['query'] = (normal['search'] + normal['rerank']) * n_qannots
    normal['total'] = normal['indexing'] + normal['query']

    n_cannots = ceil(n_dannots / C)
    n_cvecs = n_vecs_per_annot * n_cannots

    # How many annots should be re-ranked in each chunk?
    # _n_rr_chunk = sym.Max(n_rr / C * log(n_rr / C), 1)
    # _n_rr_chunk = n_rr / C
    _n_rr_chunk = n_rr

    _index_chunk = Indexer.build(n_cvecs)
    _search_chunk = n_vecs_per_annot * Indexer.search(n_cvecs)
    chunked = {}
    chunked['indexing'] = C * _index_chunk
    chunked['search'] = C * _search_chunk
    # Cost to rerank in every chunk and then merge chunks into a single list
    chunked['rerank'] = C * (SV * _n_rr_chunk) + sort(C * _n_rr_chunk)
    chunked['query'] = (chunked['search'] + chunked['rerank']) * n_qannots
    chunked['total'] = chunked['indexing'] + chunked['query']

    typed_steps = {
        'normal': normal,
        'chunked': chunked,
    }

    #
    # ===============
    # Inspect results
    # ===============

    # Symbols that will not go to infinity
    const_symbols = {
        n_rr,
        n_vecs_per_annot
    }.union(Indexer.params)

    def measure_num(n_steps, step, type_):
        print('nsteps(%s %s)' % (step, type_,))
        sym.pprint(n_steps)

    def measure_order(n_steps, step, type_):
        print('O(%s %s)' % (step, type_,))
        limiting = [
            (s, sym.oo)
            for s in n_steps.free_symbols - const_symbols
        ]
        step_order = sym.Order(n_steps, *limiting)
        sym.pprint(step_order.args[0])

    measure_dict = {
        'num': measure_num,
        'order': measure_order,
    }

    # Different methods for choosing C
    C_methods = ut.odict([
        ('none', C),
        ('const', 512),
        ('linear', n_dannots / 512),
        ('log', log(n_dannots)),
    ])

    # ---
    # What to measure?
    # ---

    steps  = [
        'indexing',
        'query'
    ]
    types_ = ['normal', 'chunked']
    measures = [
        # 'num',
        'order'
    ]
    C_method_keys = [
        'none'
        # 'const'
    ]

    grid = ut.odict([
        ('step', steps),
        ('measure', measures),
        ('k', C_method_keys),
        ('type_', types_),
    ])

    last = None

    for params in ut.all_dict_combinations(grid):
        type_ = params['type_']
        step = params['step']
        k = params['k']
        # now = k
        now = step
        if last != now:
            print('=========')
            print('\n\n=========')
        last = now
        print('')
        print(ut.repr2(params, stritems=True))
        measure_fn = measure_dict[params['measure']]
        info = typed_steps[type_]
        n_steps = info[step]
        n_steps = n_steps.subs(C, C_methods[k])
        measure_fn(n_steps, step, type_)


def num_particles():
    # https://www.youtube.com/watch?v=lpj0E0a0mlU
    import pint
    ureg = pint.UnitRegistry()
    percent = 1 / 100
    # ro_water = 1 * ureg.gram * (ureg.cm ** -3)

    # Energy density of the universe
    ro_crit = 8.64E-30  * ureg.gram * (ureg.cm ** -3)

    # fraction of energy stored in baryons
    omega_b = 0.0485

    # radius of observable universe
    L = 4.38E28 * ureg.cm

    # (93 * 1000000000 * ureg.lightyear).to_base_units()
    # L.to_base_units()

    # mass of proton/neutron
    m_p = ureg.proton_mass

    # volume of the universe
    import numpy as np
    volume_universe = ((4 * np.pi / 3) * L ** 3)

    # total energy stored in baryons
    E_baryons = (omega_b * ro_crit * volume_universe)

    # number of baryons
    N_baryons = E_baryons / m_p

    # 75% hyrdogen, 25% helium
    hyrogen_b_mass = 1 * ureg.proton_mass
    helium_b_mass = 2 * ureg.neutron_mass + 2 * ureg.proton_mass

    hydrogen_mass = 1 * ureg.electron_mass + 1 * ureg.proton_mass
    helium_mass = 2 * ureg.electron_mass + 2 * ureg.proton_mass + 2 * ureg.neutron_mass

    mass_part = .25 * helium_mass + .75 * hydrogen_mass

    # ureg.define('up_quark = 1')
    # ureg.define('down_quark = 1')
    # ureg.up_quark

    # ureg.define('proton = 2 * up_quark + 2 * down_quark')
    # ureg.dumb

    down_quark = up_quark = 1
    n_quarks_proton = 2 * up_quark + 1 * down_quark
    n_quarks_neutron = 1 * up_quark + 2 * down_quark

    n_quarks_helium = n_quarks_neutron * 2 + 2 * n_quarks_proton
    n_electrons_helsum = n_quarks_neutron * 2 + 2 * n_quarks_proton
    n_quarks_hyrogen = n_quarks_proton

    n_quarks_hyrogen * 3 + n_quarks_helium * 1

    hyrogen_b_mass * .75 + helium_b_mass * .25

    # count number of quarks to get 26/7
    N_particles = 26 / 7 * N_baryons

    human_mass = 70 * ureg.kg
    N_particles_in_human = 1.46E29

    N_humans_max = N_particles / N_particles_in_human

    earth_mass = 5.97E27 * ureg.gram
    N_humans_earth = earth_mass / human_mass

    N_humans_now = 7.5E9

    # population growth rate percent
    r = pop_growth = 1.11 * percent
    # N_humans_max / N_humans_now = np.exp(r * T)
    n_years = 1 / r * np.log(N_humans_max / N_humans_now)


    n_years = 1 / r * np.log(N_humans_earth / N_humans_now)
