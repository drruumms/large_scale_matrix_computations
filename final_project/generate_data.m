function [ A,c, I1, I2 ] = generate_data( f,g, a,b, m)
%GENERATE_DATA ) generates the data A and c of the discretized version
%                   Av = c of the PDE Lu=f on R=R1 U R2 , u=g on boundary
%       where R1 = (0,1) x (0,3), R2 = (a,a+4) x (b, b+1)
%                   and 0<a<1, 0<=b<=2 are multiples of h=1/2^m
%   and also generates the restriction operators from I1: R-> R1, I2:R->R2
%   works with any functions f,g

h = 1/(2^m); %grid spacing

%construct R1\R2' (closure of R2)
[xr1_low, yr1_low] = meshgrid(h:h:1-h, h:h:b-h);
[xr1_hi, yr1_hi] = meshgrid(h:h:1-h, b+1+h:h:3-h);
[xr1_side, yr1_side] = meshgrid(h:h:a-h, b:h:b+1);

%get f on R1\R2'
f_r1_low = f(xr1_low, yr1_low);
f_r1_hi = f(xr1_hi, yr1_hi);
f_r1_side = f(xr1_side, yr1_side);

%add actual boundary of R,R1 to RHS f
f_r1_low(1, 1:end) = f_r1_low(1, 1:end) + g(h:h:1-h, 0);
f_r1_low(1:end,end) = f_r1_low(1:end,end) + g(1, h:h:b-h)';
f_r1_low(1:end,1) = f_r1_low(1:end,1) + g(0,h:h:b-h)';
f_r1_low = reshape(f_r1_low, [],1);

f_r1_hi(end, 1:end) = f_r1_hi(end, 1:end) + g(h:h:1-h, 3);
f_r1_hi(1:end,end) = f_r1_hi(1:end,end) + g(1,b+1+h:h:3-h)';
f_r1_hi(1:end,1) = f_r1_hi(1:end,1) + g(0,b+1+h:h:3-h)';
f_r1_hi = reshape(f_r1_hi, [], 1);

f_r1_side(1:end,1) = f_r1_side(1:end,1) + g(0, b:h:b+1)'; 
f_r1_side = reshape(f_r1_side, [], 1);
%stack together
f_r1_minr2 = [f_r1_low; f_r1_side; f_r1_hi;];
%get no points in region
no_points_r1_minr2 = size(f_r1_minr2,1);

%construct R2\R1' (closure of R1)
[xr2_minr1, yr2_minr1] = meshgrid(1+h:h:a+4-h, b+h:h:b+1-h);
%get f on R2\R1'
f_r2_minr1 = f(xr2_minr1, yr2_minr1);
%add actual boundary of R,R2
f_r2_minr1(1,1:end) = f_r2_minr1(1,1:end) + g(1+h:h:a+4-h,b);
f_r2_minr1(end,1:end) = f_r2_minr1(end,1:end) + g(1+h:h:a+4-h,b+1);
f_r2_minr1(1:end,end) = f_r2_minr1(1:end,end) + g(a+4,b+h:h:b+1-h)';
%reshape into vector
f_r2_minr1 = reshape(f_r2_minr1, [], 1);
no_points_r2_minr1 = size(f_r2_minr1,1);


%contruct gamma2
[x_gamma2_lo, y_gamma2_lo] = meshgrid(a:h:1-h,b);
[x_gamma2_hi, y_gamma2_hi] = meshgrid(a:h:1-h,b+1);
[x_gamma2_left, y_gamma2_left] = meshgrid(a,b+h:h:b+1-h);
%get f on gamma2
f_gamma2 = [reshape(f(x_gamma2_lo, y_gamma2_lo),[],1); ...
            reshape(f(x_gamma2_left,y_gamma2_left),[],1); ...
            reshape(f(x_gamma2_hi,y_gamma2_hi),[],1);];
no_points_gamma2 = size(f_gamma2,1);

        
%construct R1 intersect R2
[x_cap, y_cap] = meshgrid(a+h:h:1-h, b+h:h:b+1-h);
%get f on intersection
f_cap = reshape(f(x_cap,y_cap),[],1);
no_points_cap = size(f_cap,1);


%construct gamma 1
[x_gamma1, y_gamma1] = meshgrid(1,b+h:h:b+1-h);
%get f on gamma 1
f_gamma1 = reshape(f(x_gamma1, y_gamma1),[],1);
no_points_gamma1 = size(f_gamma1,1);

%stack RHS together in order: R1\R2', Gamma2, R1 Int R2, Gamma1, R2\R1'
c = h^2*[f_r1_minr2; f_gamma2; f_cap; f_gamma1; f_r2_minr1;];

%use numbers of points in each section to partition A
no_points = no_points_r1_minr2+no_points_gamma2+no_points_cap+no_points_gamma1+no_points_r2_minr1;
%diagonal blocks
n = 1/h-2;
% Ablock1 = spdiags([-1*ones(no_points_r1_minr2,1) 4*ones(no_points_r1_minr2,1) ...
%     -1*ones(no_points_r1_minr2,1) ], [-1 0 1], no_points_r1_minr2, no_points_r1_minr2);
% Ablock2 = spdiags([ -1*ones(no_points_gamma2,1)  4*ones(no_points_gamma2,1) ...
%     -1*ones(no_points_gamma2,1) ], [-1 0 1], no_points_gamma2, no_points_gamma2);
% Ablock3 = spdiags([-1*ones(no_points_cap,1)  4*ones(no_points_cap,1) ...
%     -1*ones(no_points_cap,1) ], [-1 0 1], no_points_cap, no_points_cap);
% Ablock4 = spdiags([-1*ones(no_points_gamma1,1) 4*ones(no_points_gamma1,1) ...
%     -1*ones(no_points_gamma1,1)], [-1 0 1], no_points_gamma1, no_points_gamma1);
% Ablock5 = spdiags([-1*ones(no_points_r2_minr1,1)  4*ones(no_points_r2_minr1,1) ...
%     -1*ones(no_points_r2_minr1,1)], [-1 0 1], no_points_r2_minr1, no_points_r2_minr1);

% Ablock1 = spdiags([-1*ones(no_points_r1_minr2,1) -1*ones(no_points_r1_minr2,1)  4*ones(no_points_r1_minr2,1) ...
%     -1*ones(no_points_r1_minr2,1) -1*ones(no_points_r1_minr2,1) ], [-n -1 0 1 n], no_points_r1_minr2, no_points_r1_minr2);
% Ablock2 = spdiags([-1*ones(no_points_gamma2,1) -1*ones(no_points_gamma2,1)  4*ones(no_points_gamma2,1) ...
%     -1*ones(no_points_gamma2,1) -1*ones(no_points_gamma2,1) ], [-n -1 0 1 n], no_points_gamma2, no_points_gamma2);
% Ablock3 = spdiags([-1*ones(no_points_cap,1) -1*ones(no_points_cap,1)  4*ones(no_points_cap,1) ...
%     -1*ones(no_points_cap,1) -1*ones(no_points_cap,1) ], [-n -1 0 1 n], no_points_cap, no_points_cap);
% Ablock4 = spdiags([-1*ones(no_points_gamma1,1) -1*ones(no_points_gamma1,1)  4*ones(no_points_gamma1,1) ...
%     -1*ones(no_points_gamma1,1) -1*ones(no_points_gamma1,1) ], [-n -1 0 1 n], no_points_gamma1, no_points_gamma1);
% Ablock5 = spdiags([-1*ones(no_points_r2_minr1,1) -1*ones(no_points_r2_minr1,1)  4*ones(no_points_r2_minr1,1) ...
%     -1*ones(no_points_r2_minr1,1) -1*ones(no_points_r2_minr1,1) ], [-n -1 0 1 n], no_points_r2_minr1, no_points_r2_minr1);
% %subdiagonal blocks
% Asub1 = spdiags(-1*ones(no_points_r1_minr2,1), 0, no_points_gamma2, no_points_r1_minr2);
% Asub2 = spdiags(-1*ones(no_points_gamma2,1), 0, no_points_cap, no_points_gamma2) ...
%         + fliplr(spdiags(-1*ones(no_points_gamma2,1), 0, no_points_cap, no_points_gamma2));
% Asub3 = spdiags(-1*ones(no_points_cap,1), 0, no_points_gamma1, no_points_cap) ...
%         + fliplr(spdiags(-1*ones(no_points_cap,1), 0, no_points_gamma1, no_points_cap));
% Asub4 = spdiags(-1*ones(no_points_r2_minr1,1), 0, no_points_r2_minr1,no_points_gamma1);
% 
% 
% A = zeros(no_points, no_points);
% A(1:no_points_r1_minr2, 1:no_points_r1_minr2) = Ablock1;
% A(no_points_r1_minr2+1:no_points_r1_minr2+no_points_gamma2, 1:no_points_r1_minr2) = Asub1;
% A(1:no_points_r1_minr2, no_points_r1_minr2+1:no_points_r1_minr2+no_points_gamma2) = Asub1';
% 
% subtot = no_points_r1_minr2;
% 
% A(subtot+1:subtot+no_points_gamma2, subtot+1:subtot+no_points_gamma2) = Ablock2;
% A(subtot+no_points_gamma2+1:subtot+no_points_gamma2+no_points_cap, subtot+1:subtot+no_points_gamma2) = Asub2;
% A(subtot+1:subtot+no_points_gamma2,subtot+no_points_gamma2+1:subtot+no_points_gamma2+no_points_cap) = Asub2';
% 
% subtot = subtot+no_points_gamma2;
% 
% A(subtot+1:subtot+no_points_cap, subtot+1:subtot+no_points_cap) = Ablock3;
% A(subtot+no_points_cap+1:subtot+no_points_cap+no_points_gamma1, subtot+1:subtot+no_points_cap) = Asub3;
% A(subtot+1:subtot+no_points_cap,subtot+no_points_cap+1:subtot+no_points_cap+no_points_gamma1) = Asub3';
% 
% subtot = subtot+no_points_cap;
% 
% A(subtot+1:subtot+no_points_gamma1, subtot+1:subtot+no_points_gamma1) = Ablock4;
% A(subtot+no_points_gamma1+1:end, subtot+1:subtot+no_points_gamma1) = Asub4;
% A(subtot+1:subtot+no_points_gamma1, subtot+no_points_gamma1+1:end) = Asub4';
% 
% subtot  = subtot+no_points_gamma1;
% A(subtot+1:end, subtot+1:end) = Ablock5;

no_points_r1 = (1/h-1)*(3/h-1);
nx1 = 1/h-1;
A1 = spdiags([-1*ones(no_points_r1,1) -1*ones(no_points_r1,1)...
    4*ones(no_points_r1,1) -1*ones(no_points_r1,1) ...
    -1*ones(no_points_r1,1)], [-nx1 -1 0 1 nx1], no_points_r1, no_points_r1);
no_points_r2 = (1/h-1)*((4-a)/h-1);
nx2 = 4/h-1;
A2 = spdiags([-1*ones(no_points_r2,1) -1*ones(no_points_r2,1) ...
        4*ones(no_points_r2,1) -1*ones(no_points_r2,1) ... 
        -1*ones(no_points_r2,1)], [-nx2 -1 0 1 nx2], no_points_r2, no_points_r2);
A1 = permute_A1(A1,h,a,b);
figure(1); spy(A1)
A2 = permute_A2(A2,h,a);
figure(2); spy(A2)
no_points
no_points = no_points_r1 + no_points_r2 - no_points_cap
A = zeros(no_points, no_points);

A(1:no_points_r1, 1:no_points_r1) = A1;
size(A(end-no_points_r2+1:end, end-no_points_r2+1:end))
size(A2)
A(end-no_points_r2+1:end, end-no_points_r2+1:end) = A2;

%generate restriction operators
% no_points_r1 = no_points_r1_minr2+ no_points_gamma2+no_points_cap
% no_points_r2 = no_points_r2_minr1+ no_points_gamma1+no_points_cap;
I1 = zeros(no_points_r1, no_points);
I1(1:no_points_r1, 1:no_points_r1) = eye(no_points_r1, no_points_r1);
I2 = zeros(no_points_r2, no_points);
I2(1:end, end-no_points_r2+1:end) = eye(no_points_r2, no_points_r2);

%return sparse matrices
A = sparse(A);
I1 = sparse(I1);
I2 = sparse(I2);
end

