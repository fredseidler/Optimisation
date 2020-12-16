clear all
clc 

%--------------Variables to be optimised--------------------
% x(1) = d, spacing between lamps, m
% x(2) = z, height of lamps, m
% x(3) = l, length of lamp's arm, m
% x(4) = m, material choice of pole

%--------------Fixed system variables--------------------
t = 4000; %number of hours bulb is on per year
L = 100; % length of road being considered
c_energy = 0.156; %cost of energy per kWh
c_cable = 2.56; %cost of cabling per m
phi = 15500; 
theta = pi/2;

%--------------Fixed variables dependant on other subsystems--------------------
eta = 155; %efficiency of the bulb in lu/w
c_lamp = 10; %cost of one bulb in £

%--------------Defining the objective function--------------------
C_total = @(x)c_cable*(floor(L/x(1))*(x(2)+x(3))+100) + floor(L/x(1))*c_lamp + (floor(L/x(1)) * phi/eta * t)/1000 * c_energy + floor(L/x(1))*7.3;

%--------------Defining the optimization problem--------------------
x0 = [1, 1, 1];
A = [-2/3 1 0
      0 0 1
      0  -1 0];
b = [0 2.5 -4];
Aeq = [];
beq = [];
lb = [0 4 0];
ub = [];
nvars = 3;
nonlcon = @NL_constraints;
options_ip = optimoptions('fmincon','Display','final','Algorithm','interior-point');
options_ga = optimoptions(@ga,'Display','final');


%--------------Solving the optimization problem--------------------
tic
x_ip = fmincon(C_total,x0,A,b,Aeq,beq,lb,ub,nonlcon,options_ip);
toc

tic
x_ga = ga(C_total,nvars,A,b,Aeq,beq,lb,ub,nonlcon,options_ga);
toc

x = x_ip


%--------------Material Selection--------------------
n = floor(L/x(1));
materials = readtable('cost_of_material.csv');
materials.material_cost = n * (materials.unit_cost * (x(2)+x(3)) + materials.unit_maintenance_cost * (x(2)+x(3)));
[min_vals, min_idx] = min(materials{:,4});
best_material = materials.material(min_idx)

%--------------Final cost evaluation--------------------
C_total(x);
C_total_with_material = C_total(x) + materials.material_cost(min_idx);

%--------------Text explanation--------------------
cost_str = 'The minimised cost for a street lighting system on 100m of residential road is: £';
material_str = 'The optimum material for a lamp pole to be made of is: ';
dimension_str = 'The optimum dimensions for a street lighting system are; \n';
COST = [cost_str, num2str(round(C_total_with_material, 2))];
MATERIAL = [material_str, char(best_material)];
DIMENSION = [dimension_str, 'Distance between poles: ', num2str(round(x(1), 2)), 'm \n', 'Height of pole: ', num2str(round(x(2),2)), 'm \n', 'Length of arm: ', num2str(round(x(3),2)), 'm \n'];

fprintf(DIMENSION)
disp(MATERIAL)
disp(COST)

%--------------Non-linear constraint function--------------------
function [g1,g2] = NL_constraints(x)
phi= 15500; %This has come from the bulb subsystem
theta = pi/2; %This has come from the mirror subsystem

% Inequality constraints
g1 = 60 - (phi/(2*pi*(1- cos(theta/2))*((x(1)/2)^2 + x(2)^2 + (2.5 - x(3))^2))); % the minimum light levels required between two lamps in the centre of the road 
g2 = 120 - (phi/(2*pi*(1- cos(theta/2))*((x(1)/2)^2 + x(2)^2 + (1.5 + x(3))^2))); % the minimum light levels required between two lamps at the edge of the pavement

end