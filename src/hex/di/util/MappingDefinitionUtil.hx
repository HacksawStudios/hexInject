package hex.di.util;

import hex.di.mapping.MappingDefinition;

/**
 * ...
 * @author Francis Bourre
 */
class MappingDefinitionUtil 
{
	/** @private */ function new() throw new hex.error.PrivateConstructorException();

	public static function addToInjector<T>( mappings : Array<MappingDefinition>, target : IDependencyInjector, ?useMetadataOf : T ) : Void
	{
		if ( useMetadataOf != null ) 
		{
			var cls = Type.getClass( useMetadataOf );
			mappings = hex.di.mapping.MappingChecker.filter( cls, mappings );
		}

		for ( mapping in  mappings )
		{
			if ( mapping.toValue != null )
			{
				target.mapClassNameToValue( mapping.fromType, mapping.toValue, mapping.withName );
			}
			else
			{
				if ( mapping.asSingleton )
				{
					target.mapClassNameToSingleton( mapping.fromType, mapping.toClass, mapping.withName );
				}
				else
				{
					target.mapClassNameToType( mapping.fromType, mapping.toClass, mapping.withName );
				}
			}
			
			if ( mapping.injectInto ) 
			{
				target.injectInto( mapping.toValue );
			}
		}
	}
}
