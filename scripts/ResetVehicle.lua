-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --
-- Reset vehicle script
--
-- Purpose: This script allows you to reset your vehicles in place.
-- 
-- Authors: Timmiej93
--
-- Copyright (c) Timmiej93, 2017
-- For more information on copyright for this mod, please check the readme file on Github
--
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --

ResetVehicle = {};

function ResetVehicle.prerequisitesPresent(specializations)
	return true;
end;

function ResetVehicle:load(savegame)
	self.isSelectable = true;
	self.resetAction = ResetVehicle.resetAction
	self.callResetAction = ResetVehicle.callResetAction
	self.buttonHeldTimer = 0
	self.resetIterations = 0
end

function ResetVehicle:delete()end
function ResetVehicle:mouseEvent(posX, posY, isDown, isUp, button)end
function ResetVehicle:keyEvent(unicode, sym, modifier, isDown)end
function ResetVehicle:readStream(streamId, connection)end
function ResetVehicle:writeStream(streamId, connection)end

function ResetVehicle:update(dt)
    if self:getIsActive() and g_currentMission.controlledVehicle == self then
	-- if self:getIsActiveForInput() then
		if InputBinding.isPressed(InputBinding.T93_resetVehicle) then

            if self.buttonHeldTimer == 0 and self.resetIterations == 0 then
                self:resetAction()
                self.resetIterations = self.resetIterations + 1
            end
			self.buttonHeldTimer = self.buttonHeldTimer + dt

			if self.buttonHeldTimer > 1500 then
				self.buttonHeldTimer = self.buttonHeldTimer - 1500
				self.resetIterations = self.resetIterations + 1

				self:resetAction(self.resetIterations)
			end
		else
			if self.buttonHeldTimer ~= 0 then
				self.buttonHeldTimer = 0
                self.resetIterations = 0
			end
		end
	end
end

function ResetVehicle:draw()

	if self.isClient and self:getIsActive() then
	    g_currentMission:addHelpButtonText(g_i18n:getText("T93_RV_Reset"), InputBinding.T93_resetVehicle);
	end
end

function ResetVehicle:resetAction(extraHeight, noEventSend)

    if extraHeight == nil then
        extraHeight = 0
    end

    local vehicleToReset = self
    if vehicleToReset == nil then
        vehicleToReset = g_currentMission.controlledVehicle
    end
	ResetVehicleEvent.sendEvent(vehicleToReset, extraHeight, noEventSend)

	if extraHeight == nil then
		extraHeight = 0
	end
	
	local vehicles = {}
	local vehicleCombinations = {}
	local function processVehicle(vehicle)
        local x,y,z = getWorldTranslation(vehicle.rootNode);
        local entry = {}
        entry.vehicle = vehicle
        entry.offset = {worldToLocal(vehicle.rootNode, x,y,z)}
        entry.foldAnimTime = vehicle.foldAnimTime
        table.insert(vehicles, entry);

        for _,implement in pairs(vehicle.attachedImplements) do
            processVehicle(implement.object);
            local entry = {
            	vehicle = vehicle,
            	object = implement.object,
            	jointDescIndex = implement.jointDescIndex, 
            	inputAttacherJointDescIndex = implement.object.inputAttacherJointDescIndex
        	}
        	table.insert(vehicleCombinations, entry)
        end;
        
        for i=table.getn(vehicle.attachedImplements), 1, -1 do
            vehicle:detachImplement(1, true);
        end;

        if not vehicle:isa(RailroadVehicle) then  -- rimuovere se ci sono problemi.
            vehicle:removeFromPhysics();
        end;
    end;

    processVehicle(vehicleToReset);

    for k,vehicle in pairs(vehicles) do
    	local x,y,z = getWorldTranslation(vehicle.vehicle.rootNode)

    	if k>1 then
    		x,_,z = localToWorld(vehicle.vehicle.rootNode, unpack(vehicle.offset))
    	end

    	local rx,ry,rz = localDirectionToWorld(vehicle.vehicle.rootNode, 0, 0, 1);
	    local length = Utils.vector2Length(rx,rz);
	    local direction = 0;
	    if length ~= 0.0 then
	        direction = (math.pi*2)-(math.atan2(rz/length,rx/length)-0.5*math.pi) % (2*math.pi);
	    end;
	    vehicle.vehicle:setRelativePosition(x,0.5+extraHeight,z, direction)
	    vehicle.vehicle:addToPhysics();

        if vehicle.foldAnimTime ~= nil then
            Foldable.setAnimTime(vehicle.vehicle, vehicle.foldAnimTime, false)
        end
    end

    for _,combination in pairs(vehicleCombinations) do
    	combination.vehicle:attachImplement(combination.object, combination.inputAttacherJointDescIndex, combination.jointDescIndex, true, nil, nil, false)
    end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Events

ResetVehicleEvent = {}
local ResetVehicleEvent_mt = Class(ResetVehicleEvent, Event);

InitEventClass(ResetVehicleEvent, "ResetVehicleEvent");

function ResetVehicleEvent:emptyNew()
    local self = Event:new(ResetVehicleEvent_mt);
    return self;
end;

function ResetVehicleEvent:new(vehicle, extraHeight)
    local self = ResetVehicleEvent:emptyNew()
    self.vehicle = vehicle
    self.extraHeight = extraHeight
    return self;
end;

function ResetVehicleEvent:readStream(streamId, connection)
    self.vehicle = networkGetObject(streamReadInt32(streamId));
    self.extraHeight = streamReadInt8(streamId)
    self:run(connection)
end;

function ResetVehicleEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, networkGetObjectId(self.vehicle));
    streamWriteInt8(streamId, self.extraHeight)
end;

function ResetVehicleEvent:run(connection)
    if self.vehicle ~= nil then
        self.vehicle:resetAction(self.extraHeight, true)
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(ResetVehicleEvent:new(self.vehicle, self.extraHeight), nil, connection, self.vehicle)
    end
end

function ResetVehicleEvent.sendEvent(vehicle, extraHeight, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(ResetVehicleEvent:new(vehicle, extraHeight), nil, nil, vehicle);
        else
            g_client:getServerConnection():sendEvent(ResetVehicleEvent:new(vehicle, extraHeight));
        end
    end
end