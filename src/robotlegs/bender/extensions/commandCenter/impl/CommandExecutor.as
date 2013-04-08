//------------------------------------------------------------------------------
//  Copyright (c) 2009-2013 the original author or authors. All Rights Reserved.
//
//  NOTICE: You are permitted to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//------------------------------------------------------------------------------

package robotlegs.bender.extensions.commandCenter.impl
{
	import org.swiftsuspenders.Injector;

	import robotlegs.bender.extensions.commandCenter.api.ICommandExecutor;
	import robotlegs.bender.extensions.commandCenter.api.ICommandMapping;
	import robotlegs.bender.framework.impl.applyHooks;
	import robotlegs.bender.framework.impl.guardsApprove;

	public class CommandExecutor implements ICommandExecutor
	{

		/*============================================================================*/
		/* Private Properties                                                         */
		/*============================================================================*/

		private var _injector:Injector;

		private var _removeMapping:Function;

		/*============================================================================*/
		/* Constructor                                                                */
		/*============================================================================*/

		public function CommandExecutor(injector:Injector, removeMapping:Function)
		{
			_injector = injector;
			_removeMapping = removeMapping;
		}

		/*============================================================================*/
		/* Public Functions                                                           */
		/*============================================================================*/

		public function execute(mappings:Vector.<ICommandMapping>, payload : CommandPayloadConfig = null):void
		{
			const length:int = mappings.length;
			const hasPayload:Boolean = payload && payload.hasPayload();
			for (var i:int = 0; i < length; i++)
			{
				var mapping:ICommandMapping = mappings[i];
				var command:Object = null;

				hasPayload && mapPayload(payload);

				if (mapping.guards.length == 0 || guardsApprove(mapping.guards, _injector))
				{
					const commandClass:Class = mapping.commandClass;
					mapping.fireOnce && _removeMapping(mapping);

					command = _injector
						? _injector.instantiateUnmapped(commandClass)
						: new commandClass();

					if (mapping.hooks.length > 0)
					{
						_injector && _injector.map(commandClass).toValue(command);
						applyHooks(mapping.hooks, _injector);
						_injector && _injector.unmap(commandClass);
					}
				}

				hasPayload && unmapPayload(payload);

				if (command)
				{
					mapping.executeMethod && command[mapping.executeMethod]();
				}
			}
		}

		/*============================================================================*/
		/* Private Functions                                                          */
		/*============================================================================*/


		private function mapPayload(config : CommandPayloadConfig):void
		{
			var i:uint = config.payloadLength;
			while (i--)
			{
				_injector.map(config.payloadClasses[i]).toValue(config.payloadValues[i]);
			}
		}

		private function unmapPayload(config : CommandPayloadConfig):void
		{
			var i:uint = config.payloadLength;
			while (i--)
			{
				_injector.unmap(config.payloadClasses[i]);
			}
		}
	}
}
