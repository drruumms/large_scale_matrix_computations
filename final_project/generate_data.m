function [ A,c, I1, I2 ] = generate_data( f,g, a,b, m)
%GENERATE_DATA ) generates the data A and c of the discretized version
%                   Av = c of the PDE Lu=f on R=R1 U R2 , u=g on boundary
%       where R1 = (0,1) x (0,3), R2 = (a,a+4) x (b, b+1)
%                   and 0<a<1, 0<=b<=2 are multiples of h=1/2^m
%   and also generates the restriction operators from I1: R-> R1, I2:R->R2
%   works with any functions f,g

h = 1/(2^m); %grid spacing

%construct R1\R2' (closure of R2)
if b~=0
    [xr1_low, yr1_low] = meshgrid(h:h:1-h, h:h:b-h);
    %get f on lowest box
    f_r1_low = h^2*f(xr1_low, yr1_low);
    %add boundary
    f_r1_low(1, 1:end) = f_r1_low(1, 1:end) + g(h:h:1-h, 0);
    f_r1_low(1:end,end) = f_r1_low(1:end,end) + g(1, h:h:b-h)';
    f_r1_low(1:end,1) = f_r1_low(1:end,1) + g(0,h:h:b-h)';
    f_r1_low = reshape(f_r1_low', [],1);
end
if b~=2
    [xr1_side, yr1_side] = meshgrid(h:h:a-h, b:h:b+1);
    [xr1_hi, yr1_hi] = meshgrid(h:h:1-h, b+1+h:h:3-h);
    %get f on R1\R2'
    f_r1_hi = h^2*f(xr1_hi, yr1_hi);
    f_r1_side = h^2*f(xr1_side, yr1_side);

    %add actual boundary of R,R1 to RHS f
    f_r1_hi(end, 1:end) = f_r1_hi(end, 1:end) + g(h:h:1-h, 3);
    f_r1_hi(1:end,end) = f_r1_hi(1:end,end) + g(1,b+1+h:h:3-h)';
    f_r1_hi(1:end,1) = f_r1_hi(1:end,1) + g(0,b+1+h:h:3-h)';
    f_r1_hi = reshape(f_r1_hi', [], 1);

    f_r1_side(1:end,1) = f_r1_side(1:end,1) + g(0, b:h:b+1)'; 
    f_r1_side = reshape(f_r1_side', [], 1);
else
    [xr1_side, yr1_side] = meshgrid(h:h:a-h, b:h:3-h);
    %get f on R1\R2'
    f_r1_side = h^2*f(xr1_side, yr1_side);

    %add actual boundary of R,R1 to RHS f
    f_r1_side(end, 1:end) = f_r1_side(end, 1:end) + g(h:h:a-h, 3);
    f_r1_side(1:end,end) = f_r1_side(1:end,end) + g(1,b:h:3-h)';
    f_r1_side(1:end,1) = f_r1_side(1:end,1) + g(0,b:h:3-h)';
    f_r1_side = reshape(f_r1_side', [], 1);
end
%stack together
if b==0
    f_r1_minr2 = [f_r1_side; f_r1_hi;];
else if b==2
        f_r1_minr2 = [f_r1_low; f_r1_side;];
    else
    f_r1_minr2 = [f_r1_low; f_r1_side; f_r1_hi;];
    end
end
%get no points in region
no_points_r1_minr2 = size(f_r1_minr2,1);

%construct R2\R1' (closure of R1)
[xr2_minr1, yr2_minr1] = meshgrid(1+h:h:a+4-h, b+h:h:b+1-h);
%get f on R2\R1'
f_r2_minr1 = h^2*f(xr2_minr1, yr2_minr1);
%add actual boundary of R,R2
f_r2_minr1(1,1:end) = f_r2_minr1(1,1:end) + g(1+h:h:a+4-h,b);
f_r2_minr1(end,1:end) = f_r2_minr1(end,1:end) + g(1+h:h:a+4-h,b+1);
f_r2_minr1(1:end,end) = f_r2_minr1(1:end,end) + g(a+4,b+h:h:b+1-h)';
%reshape into vector
f_r2_minr1 = reshape(f_r2_minr1', [], 1);
no_points_r2_minr1 = size(f_r2_minr1,1);

%contruct gamma2
[x_gamma2_left, y_gamma2_left] = meshgrid(a,b+h:h:b+1-h);
%get f on gamma2
f_gamma2_left = h^2*f(x_gamma2_left,y_gamma2_left);
if b~=0
    [x_gamma2_lo, y_gamma2_lo] = meshgrid(a:h:1-h,b);
    %get f on gamma2
    f_gamma2_lo = h^2*f(x_gamma2_lo, y_gamma2_lo);
    %add actual boundary
    f_gamma2_lo(end,1) = f_gamma2_lo(end,1) + g(1,b);
else
    %add actual boundary
    f_gamma2_left(1,1) = f_gamma2_left(1,1) + g(a,0);
end
if b~=2
    [x_gamma2_hi, y_gamma2_hi] = meshgrid(a:h:1-h,b+1);
    %get f on gamma2
    f_gamma2_hi = h^2*f(x_gamma2_hi,y_gamma2_hi);
    %add actual boundary
    f_gamma2_hi(end,1) = f_gamma2_hi(end,1) + g(1,b+1);
    else
    %add actual boundary
    f_gamma2_left(end,end) = f_gamma2_left(end,end) + g(a,3);
end

%combine & reshape
if b~=0
    if b~=2
        f_gamma2 = [reshape(f_gamma2_lo',[],1); ...
            reshape(f_gamma2_left',[],1); ...
            reshape(f_gamma2_hi',[],1);];
    else
        f_gamma2 = [reshape(f_gamma2_lo',[],1); ...
            reshape(f_gamma2_left',[],1);];
    end
else
    f_gamma2 = [reshape(f_gamma2_left',[],1); ...
            reshape(f_gamma2_hi',[],1);];
end
no_points_gamma2 = size(f_gamma2,1);

        
%construct R1 intersect R2
[x_cap, y_cap] = meshgrid(a+h:h:1-h, b+h:h:b+1-h);
%get f on intersection
f_cap = reshape(h^2*f(x_cap,y_cap)',[],1);
no_points_cap = size(f_cap,1);

%construct gamma 1
[x_gamma1, y_gamma1] = meshgrid(1,b+h:h:b+1-h);
%get f on gamma 1
f_gamma1 = h^2*f(x_gamma1, y_gamma1);
%add actual boundary
f_gamma1(1,1) = f_gamma1(1,1) + g(1,b);
f_gamma1(1,end) = f_gamma1(1,end) + g(1,b+1);
%reshape
f_gamma1 = reshape(f_gamma1',[],1);
no_points_gamma1 = size(f_gamma1,1);

%stack RHS together in order: R1\R2', Gamma2, R1 Int R2, Gamma1, R2\R1'
c = [f_r1_minr2; f_gamma2; f_cap; f_gamma1; f_r2_minr1;];

%use numbers of points in each section to partition A
no_points = no_points_r1_minr2+no_points_gamma2+no_points_cap+no_points_gamma1+no_points_r2_minr1;

%create and permute submatrices A1,A2
no_points_r1 = (1/h-1)*(3/h-1);
nx1 = 1/h-1;
A1 = spdiags([-1*ones(no_points_r1,1) -1*ones(no_points_r1,1)...
    4*ones(no_points_r1,1) -1*ones(no_points_r1,1) ...
    -1*ones(no_points_r1,1)], [-nx1 -1 0 1 nx1], no_points_r1, no_points_r1);
no_points_r2 = (1/h-1)*(4/h-1);
nx2 = 4/h-1;
A2 = spdiags([-1*ones(no_points_r2,1) -1*ones(no_points_r2,1) ...
        4*ones(no_points_r2,1) -1*ones(no_points_r2,1) ... 
        -1*ones(no_points_r2,1)], [-nx2 -1 0 1 nx2], no_points_r2, no_points_r2);
A1 = permute_A1(A1,h,a,b);
A2 = permute_A2(A2,h,a);

%Combine to get A
A = sparse(no_points, no_points);
A(1:no_points_r1, 1:no_points_r1) = A1;
A(end-no_points_r2+1:end, end-no_points_r2+1:end) = A2;

%generate restriction operators
I1 = sparse(no_points_r1, no_points);
I1(1:no_points_r1, 1:no_points_r1) = eye(no_points_r1, no_points_r1);
I2 = sparse(no_points_r2, no_points);
I2(1:end, end-no_points_r2+1:end) = eye(no_points_r2, no_points_r2);

%return sparse matrices
A = sparse(A);
I1 = sparse(I1);
I2 = sparse(I2);
end

