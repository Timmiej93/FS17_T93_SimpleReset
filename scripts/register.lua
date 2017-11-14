-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --
-- Register script by Rival, modified by Timmiej93
--
-- This file is inspired by the register script as created by 'Rival'.
--
-- Purpose: This file registers the specialisation 'WaterTrailerFix', and inserts it into each 
--     vehicle with the 'waterTrailer' specialization. 
-- 
-- Authors: Timmiej93
--
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --

SpecializationUtil.registerSpecialization("ResetVehicle", "ResetVehicle", g_currentModDirectory.."scripts/ResetVehicle.lua")

rvRegister = {};

function rvRegister:loadMap(name)
	if self.firstRun == nil then
		self.firstRun = false;
		
		for k,vehicleType in pairs(VehicleTypeUtil.vehicleTypes) do
			if vehicleType ~= nil then
				local allowInsertion = true;
				for i = 1, table.maxn(vehicleType.specializations) do
					local specialization = vehicleType.specializations[i];
					if specialization ~= nil and specialization == SpecializationUtil.getSpecialization("drivable") then
						local vehicleName = vehicleType.name 
						local location = string.find(vehicleName, ".", nil, true)
						if location ~= nil then
							local name = string.sub(vehicleName, 1, location-1);
							if rawget(SpecializationUtil.specializations, string.format("%s.ResetVehicle", name)) ~= nil then
								allowInsertion = false;								
							end;							
						end;
						if allowInsertion then	
							table.insert(vehicleType.specializations, SpecializationUtil.getSpecialization("ResetVehicle"));
							break;
						end;
					end;
				end;
			end;	
		end;
	end;
end;

function rvRegister:deleteMap()end;
function rvRegister:keyEvent(unicode, sym, modifier, isDown)end;
function rvRegister:mouseEvent(posX, posY, isDown, isUp, button)end;
function rvRegister:update(dt)end;
function rvRegister:draw()end;

addModEventListener(rvRegister);