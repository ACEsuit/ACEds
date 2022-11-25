
using ACEds.MatrixModels
using ACEds
using JuLIP, ACE
using ACEbonds: EllipsoidBondEnvelope #, cutoff_env
using ACE: EuclideanMatrix, EuclideanVector
using ACEds.Utils: SymmetricBond_basis, SymmetricBondSpecies_basis
using ACEds: SymmetricEuclideanMatrix
using LinearAlgebra


n_bulk = 2
rcutbond = 2.0*rnn(:Al)
rcutenv = 2.5 * rnn(:Al)
zcutenv = 3.5 * rnn(:Al)

rcut = 2.0 * rnn(:Al)

zAl = AtomicNumber(:Al)
zTi = AtomicNumber(:Ti)
species = [:Al,:Ti]


env_on = SphericalCutoff(rcut)
env_off = EllipsoidCutoff(rcutbond, rcutenv, zcutenv)
#EllipsoidBondEnvelope(r0cut, rcut, zcut; p0=1, pr=1, floppy=false, λ= 0.0)

# ACE.get_spec(offsite)



maxorder = 2
r0 = .4 * rcut
Bsel = ACE.SparseBasis(;maxorder=maxorder, p = 2, default_maxdeg = 5) 
RnYlm = ACE.Utils.RnYlm_1pbasis(;   r0 = r0, 
                                rcut=rcut,
                                rin = 0.0,
                                trans = PolyTransform(2, r0), 
                                pcut = 2,
                                pin = 0
                                )

Bz = ACE.Categorical1pBasis(species; varsym = :mu, idxsym = :mu )
#onsite_posdef = ACE.SymmetricBasis(EuclideanVector(Float64), RnYlm, Bsel;);
onsite = ACE.SymmetricBasis(SymmetricEuclideanMatrix(Float64), RnYlm * Bz, Bsel;);
offsite = SymmetricBondSpecies_basis(EuclideanMatrix(Float64), Bsel;species=species);
offsite = ACEds.symmetrize(offsite; varsym = :mube, varsumval = :bond)
#offsite_sym = symmetrize(offsite)
# promote_type(eltype(onsite.A2Bmap), eltype(θ))
gen_param(N) = randn(N) ./ (1:N).^2
n_on = length(onsite)
cTi = gen_param(n_on)
cAl = gen_param(n_on)
n_off = length(offsite)
cAl2 = gen_param(n_off)
cTi2 = gen_param(n_off)
cAlTi = gen_param(n_off)


models_on = Dict(  zTi => ACE.LinearACEModel(onsite, cTi), 
zAl => ACE.LinearACEModel(onsite, cAl))

models_off = Dict( (zAl,zAl) => ACE.LinearACEModel(offsite, cAl2),
(zAl,zTi) => ACE.LinearACEModel(offsite, cAlTi),
(zTi,zTi) => ACE.LinearACEModel(offsite, cTi2))

m = ACEMatrixModel( OnSiteModels(models_on, env_on ), OffSiteModels(models_off, env_off));

OnSiteModels(models_on, env_on );
OffSiteModels(models_off, env_off);
mb = basis(m);

# offsite
# m = models_off[(zAl,zTi)]
# set_params!(m,cAlTi )

# set_params!(m.evaluator, m.basis, cAlTi )
# eltype(m.basis.A2Bmap)
# eltype(cAlTi)
# len_AA = length(m.evaluator.pibasis)
# zeros(promote_type(eltype(basis.A2Bmap), eltype(cAlTi)), len_AA)

# promote_type(eltype(m.basis.A2Bmap), eltype(cAlTi))

# models_off[(zAl,zTi)]
#allocate_Gamma(M::ACEMatrixBasis, at::Atoms, T=Float64)


at = bulk(:Al, cubic=true)*2
at.Z[2:2:end] .= zTi
rattle!(at,0.1)
#set_pbc!(at, [false,false,false])
#Q = ACE.Random.rand_rot()
typeof(at)
Γ = Gamma(m,at);
N = size(Γ,1)
norm(Γ[1,2]-transpose(Γ[2,1]))
er = sum(norm(Γ[i,j]-transpose(Γ[j,i])) for i in 1:N for j in 1:N if i!=j)
max_er = maximum(norm(Γ[i,j]-transpose(Γ[j,i])) for i in 1:N for j in 1:N if i!=j)
max_rel_er = maximum(norm(Γ[i,j]-transpose(Γ[j,i])/norm(Γ[i,j])) for i in 1:N for j in 1:N if norm(Γ[i,j])>0 && i !=j)
maxval = maximum(norm(Γ[i,j]) for i in 1:N for j in 1:N if i!=j)

norm(Γ-transpose(Γ))
norm(Γ-transpose(transpose.(Γ)))
transpose(transpose.(Γ))[1,2]
Γ[1,2]
@show Γ[1,2]
@show transpose(transpose.(Γ))[2,1]
@show Γ[2,1]
@show transpose(Γ)[1,2]


@show er
@show max_er
@show max_rel_er
@show maxval

Γb1 = ACEds.MatrixModels.allocate_Gamma(mb, at, Float64);

Γb1 = ACEds.MatrixModels.Gamma(mb, at)

Γb1-Γ
B = ACEds.MatrixModels.allocate_B(mb, at, :sparse);

B = ACEds.MatrixModels.evaluate(mb, at, :sparse)
θ= params(mb)
Γb2 = Matrix(sum(θ .*  B))
sum(norm.(Γb2-Γ))

ACEds.MatrixModels.get_interaction(mb, 1300)

ACEds.MatrixModels.get_range(mb, (AtomicNumber(:Al), AtomicNumber(:Al)))



length(B)
nparams(mb)
θ = params(mb)
set_params!(mb,θ)


θ2 = params(mb)
ons = getfield(mb, :onsite);
ons.models
getfield(mb, :onsite).models;
for site in [:onsite,:offsite]
    @show keys(getfield(mb, :onsite).models)
end

ons2 = mb.onsite;
typeof(ons2)
typeof(getfield(mb, :onsite))
# G = Γ - transpose(Γ)
# G[1,2]
# R = [(a=2,g=4),(a=3,g=5)]
# sym = :a

# function mytest(sym)
#     for r in R
#         nt = @eval ($sym=getfield($r,sym),g=$r.g)
#         @show nt
#         setindex( nt, sym, 123 )
#         @show nt
#     end
# end

# mytest(sym)

# R = [(a=2,g=4),(a=3,g=5)]
# sym = :a
# function mytest(sym)
#     for r in R
#         nt = (eval(:sym)=getfield(r,sym),g=r.g)
#         @show nt
#     end
# # end
# mytest(sym)

# R[1][:a] 

# R = [(a=2,g=4),(a=3,g=5)]
# NP = typeof(R[1])
# NP((1,2))
# NP == NamedTuple{(sym, :g), Tuple{Int64, Int64}}


# Rs1 = SVector{3, Float64}[[2.0522183783186474, -1.0357562163946867, 1.0092459639109808], [2.0458254107438583, 1.0395617539834898, -1.0400794102296054], [-4.045670566076657, -1.0679977492582897, -1.0030491373233499], [4.054329433923343, -1.0679977492582897, -1.0030491373233499], [-4.028518144650399, 1.0448254270367197, 0.9804946995476096], [4.0714818553496, 1.0448254270367197, 0.9804946995476096], [-2.0356001284950658, -1.0540173282432126, 1.041297929414911], [-2.0846769185234875, 1.0250991243581056, -0.9418568694774727], [-0.028143491103329588, 3.0789124257098823, -0.9740914662234066], [-0.056794096207505085, -3.0845198792550463, 1.0728714387355693], [-0.056794096207505085, 5.015480120744953, 1.0728714387355693], [2.0280544670856777, 3.0677204466767583, 0.9950721397383608], [1.9968386657806831, -3.05833920872812, -0.9704958035000502], [1.9968386657806831, 5.041660791271879, -0.9704958035000502], [-4.05495511736325, 3.082432115725833, -1.0144877392349905], [4.045044882636749, 3.082432115725833, -1.0144877392349905], [-4.0855571021885115, -3.026293280500307, 1.075753103252826], [4.014442897811488, -3.026293280500307, 1.075753103252826], [-1.9780564489938026, 2.9892632702528, 1.0142713294974697], [-1.9859524995110966, -3.085699649383303, -1.0402917669863818], [-1.9859524995110966, 5.014300350616696, -1.0402917669863818], [-0.014129742821151758, -0.9759860241424074, 3.0172178461319836], [-0.004738878029297844, 0.994597962519395, -3.010851726419892], [-0.004738878029297844, 0.994597962519395, 5.089148273580108], [2.0667680487859252, -1.0015349077113627, -2.9940059249762747], [2.0667680487859252, -1.0015349077113627, 5.105994075023725], [2.022605955588163, 1.0049723339847834, 3.0131503395780124], [-4.081003117237069, -1.004807196117426, 3.070569041605201], [4.018996882762931, -1.004807196117426, 3.070569041605201], [-4.015785090255356, 0.9671343111274464, -2.9873885994160254], [-2.018481989931499, -1.0404013017490041, -3.059139588681017], [-2.018481989931499, -1.0404013017490041, 5.040860411318982], [-2.0358031198927486, 1.0096251733011052, 3.055488523834616], [-0.019920415378124723, 2.982622500972738, 3.046789094079247], [-0.05483826849640483, -3.076728001689523, -2.9819884543148074], [1.9694838681100153, 3.0190815752176148, -3.0554399150908935], [1.9819540808010343, -3.074770544206706, 3.009941612703316], [-1.9840754793047326, 3.0414184509094406, -3.076865405486153], [-2.0070985399295402, -3.0252375373728797, 3.034407232234371]]

# Rs2 = SVector{3, Float64}[[2.0522183783186483, -1.0357562163946876, 1.0092459639109805], [2.0458254107438596, 1.0395617539834898, -1.0400794102296054], [-4.045670566076656, -1.0679977492582906, -1.0030491373233499], [4.0543294339233436, -1.0679977492582906, -1.0030491373233499], [-4.028518144650398, 1.0448254270367197, 0.9804946995476094], [4.071481855349601, 1.0448254270367197, 0.9804946995476094], [-2.035600128495065, -1.0540173282432135, 1.0412979294149107], [-2.0846769185234866, 1.0250991243581056, -0.9418568694774736], [-0.028143491103329588, -5.021087574290117, -0.9740914662234061], [-0.028143491103329588, 3.0789124257098823, -0.9740914662234061], [-0.056794096207505085, -3.0845198792550454, 1.0728714387355691], [2.0280544670856786, -5.032279553323241, 0.99507213973836], [2.0280544670856786, 3.0677204466767583, 0.99507213973836], [1.996838665780684, -3.058339208728119, -0.9704958035000502], [4.04504488263675, 3.082432115725833, -1.0144877392349905], [-4.085557102188511, -3.026293280500307, 1.0757531032528258], [4.014442897811489, -3.026293280500307, 1.0757531032528258], [-1.9780564489938017, -5.110736729747201, 1.0142713294974695], [-1.9780564489938017, 2.9892632702528, 1.0142713294974695], [-1.9859524995110958, -3.085699649383303, -1.0402917669863818], [-0.014129742821151758, -0.9759860241424074, -5.082782153868017], [-0.014129742821151758, -0.9759860241424074, 3.0172178461319827], [-0.004738878029298, 0.994597962519395, -3.010851726419893], [2.066768048785926, -1.0015349077113627, -2.9940059249762747], [2.0226059555881637, 1.0049723339847834, -5.086849660421987], [2.0226059555881637, 1.0049723339847834, 3.0131503395780124], [-4.015785090255355, 0.9671343111274464, -2.9873885994160263], [4.084214909744644, 0.9671343111274464, -2.9873885994160263], [-2.018481989931498, -1.040401301749005, -3.0591395886810178], [-2.0358031198927478, 1.0096251733011052, -5.0445114761653835], [-2.0358031198927478, 1.0096251733011052, 3.055488523834616], [-0.019920415378124723, 2.982622500972738, 3.046789094079246], [-0.05483826849640483, -3.076728001689522, -2.9819884543148083], [1.969483868110016, 3.0190815752176148, -3.0554399150908935], [1.981954080801035, -3.074770544206706, 3.009941612703316], [-1.9840754793047317, 3.0414184509094406, -3.0768654054861537], [-2.0070985399295393, -3.025237537372879, 3.0344072322343703]];

# Rs12 = [ round.(r, digits = 3) for r in cat(Rs1,Rs2,dims=1)]
# S1 = unique(Rs12)

# d = [norm(r1-r2) for (r1,r2) in zip(Rs1,Rs2)]