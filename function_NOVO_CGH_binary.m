function [ NOVOCGH ] = function_NOVO_CGH_binary( System, HStacks, Masks,Depths,NormOptions )
% This computes NOVO-CGH holgorams with binary targets. 
if System.verbose == 1
    disp(['NOVO-CGH with Binary Targets, computation begins']);
end;
%Initialize phase guess with a superposition
vv = System.verbose;
System.verbose = 0;
[ Superposition ] = function_Superposition( System,HStacks,Masks);
%Calculate intensity in reconstruction to normalize thresholds
[ Superposition.Intensity_Reconstruction ] = function_VolumeIntensity(System, Superposition.phase,HStacks );
System.verbose = vv;
pct9999 = prctile(Superposition.Intensity_Reconstruction(:), 99.99);
prctile(Superposition.Intensity_Reconstruction(:), 99.9);
pct100 = max(Superposition.Intensity_Reconstruction(:));
thresholdh = NormOptions.HighThreshold * (pct9999 + pct100)/2;
thresholdl = NormOptions.LowThreshold * thresholdh;

% Define functions for mask kernel, and optimization local paramenters
kernelfun = @(i1, i2) HStacks(:,:,i1:i2);
maskfun = @(i1, i2) Masks(:,:,i1:i2);
f = @(x)function_FunObj_binary( x, System.source, Depths, System.Nx, System.Ny, thresholdh, thresholdl, maskfun, kernelfun, System.useGPU);
if System.verbose == 1; tic;end;
if System.verbose==1 ; displayoption = 'iter'; else; displayoption = 'off'; end
matlab_options = optimoptions('fmincon','GradObj','on', 'display', displayoption, ...
    'algorithm','interior-point','Hessian','lbfgs', 'MaxFunEvals', 500, 'MaxIter', System.maxiter,...
    'TolX', 1e-20, 'TolFun', 1e-12);
lb = -inf(System.Nx*System.Ny, 1);
ub = inf(System.Nx*System.Ny, 1);

%Optimize 
phase = fmincon(f,Superposition.phase,[],[],[],[],lb,ub,[],matlab_options);

%Reformat result to extract hologram
phase = reshape(phase, [System.Nx, System.Ny]);
phase = mod(phase, 2*pi) - pi;

hologram = System.source.*exp(1i * phase);

NOVOCGH.hologram=hologram;
NOVOCGH.phase=phase;
if System.verbose == 1
    t = toc;
    disp(['NOVO-CGH with Binary Targets - Completed in ' int2str(t) ' seconds !']);
end;
end

