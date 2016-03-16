package hex.di;

import hex.di.IDependencyInjector;
import hex.di.error.InjectorException;
import hex.di.mapping.InjectionMapping;
import hex.di.reflect.ClassDescription;
import hex.di.reflect.IClassDescriptionProvider;
import hex.di.annotation.AnnotationDataProvider;
import hex.di.reflect.ClassDescriptionProvider;
import hex.event.EventDispatcher;
import hex.event.IEventListener;
import hex.log.Stringifier;

/**
 * ...
 * @author Francis Bourre
 */
class SpeedInjector implements IDependencyInjector
{
	var _ed						: EventDispatcher<IEventListener, InjectionEvent>;
	var _mapping				: Map<String,InjectionMapping>;
	var _processedMapping 		: Map<String,Bool>;
	var _parentInjector			: SpeedInjector;
	var _classDescriptor		: IClassDescriptionProvider;

	static public function purgeCache() : Void
	{

	}

	public function new() 
	{
		this._classDescriptor	= new ClassDescriptionProvider( new AnnotationDataProvider( ISpeedInjectorContainer ) );

		this._ed 				= new EventDispatcher<IEventListener, InjectionEvent>();
		this._mapping 			= new Map<String,InjectionMapping>();
		this._processedMapping 	= new Map<String,Bool>();
	}

	public function createChildInjector() : SpeedInjector
	{
		var injector 				= new SpeedInjector();
		injector._parentInjector 	= this;
		return injector;
	}

	//
	public function addEventListener( eventType : String, callback : InjectionEvent->Void ) : Bool
	{
		return this._ed.addEventListener( eventType, callback );
	}

	public function removeEventListener( eventType : String, callback : InjectionEvent->Void ) : Bool
	{
		return this._ed.removeEventListener( eventType, callback );
	}

	public function mapToValue( clazz : Class<Dynamic>, value : Dynamic, name : String = '' ) : Void
	{
		this.map( clazz, name ).toValue( value );
	}

	public function mapToType( clazz : Class<Dynamic>, type : Class<Dynamic>, name:String = '' ) : Void
	{
		this.map( clazz, name ).toType( type );
	}

	public function mapToSingleton( clazz : Class<Dynamic>, type : Class<Dynamic>, name:String = '' ) : Void
	{
		this.map( clazz, name ).toSingleton( type );
	}

    public function getInstance( type : Class<Dynamic>, name : String = '', targetType : Class<Dynamic> = null ) : Dynamic
	{
		var mappingID : String = Type.getClassName( type ) + '|' + name;
		var mapping : InjectionMapping = this._mapping[ mappingID ];

		if ( this._mapping[ mappingID ] != null )
		{
			return mapping.provider.getResult( this );
		}
		else if ( this._parentInjector != null )
		{
			return this._parentInjector.getInstance( type, name );
		}
		else
		{
			return null;
		}
	}

    public function instantiateUnmapped( type : Class<Dynamic> ) : Dynamic
	{
		var classDescription : ClassDescription = this._classDescriptor.getClassDescription( type );

		var instance : Dynamic;
		if ( classDescription != null && classDescription.constructorInjection != null )
		{
			instance = classDescription.constructorInjection.createInstance( type, this );
		}
		else
		{
			instance = Type.createInstance( type, [] );
		}

		this._ed.dispatchEvent( new InjectionEvent( InjectionEvent.POST_INSTANTIATE, this, instance, type ) );
		
		if ( classDescription != null )
		{
			this._applyInjection( instance, type, classDescription );
		}

		return instance;
	}

    public function getOrCreateNewInstance( type : Class<Dynamic> ) : Dynamic
	{
		return null;
	}
	
	public function hasMapping( type : Class<Dynamic>, name : String = '' ) : Bool
	{
		var mappingID : String = Type.getClassName( type ) + '|' + name;
		if ( this._mapping[ mappingID ] != null )
		{
			return true;
		}
		else if ( this._parentInjector != null )
		{
			return this._parentInjector.hasMapping( type, name );
		}
		else
		{
			return false;
		}
	}
	
	public function unmap( type : Class<Dynamic>, name : String = '' ) : Void
	{
		var mappingID 	: String 			= Type.getClassName(type) + '|' + name;
		var mapping 	: InjectionMapping 	= this._mapping[ mappingID ];

		if ( mapping == null )
		{
			throw new InjectorException( "unmap failed with mapping named '" + mappingID + "' @" + Stringifier.stringify( this ) );
		}

		//mapping.getProvider().destroy();
		this._mapping.remove( mappingID );
	}
	
	//
	public function hasDirectMapping( type : Class<Dynamic>, name : String = '' ) : Bool
	{
		var mappingID : String = Type.getClassName( type ) + '|' + name;
		return this._mapping[ mappingID ] != null;
	}

    public function satisfies( type : Class<Dynamic>, name : String = '' ) : Bool
	{
		var mappingID : String = Type.getClassName( type ) + '|' + name;
		var mapping : InjectionMapping = this._mapping[ mappingID ];

		if ( this._mapping[ mappingID ] != null )
		{
			return mapping.provider != null;
		}
		else if ( this._parentInjector != null )
		{
			return this._parentInjector.satisfies( type, name );
		}
		else
		{
			return false;
		}
	}

	public function satisfiesDirectly( type : Class<Dynamic>, name : String = '' ) : Bool
	{
		var mappingID : String = Type.getClassName( type ) + '|' + name;
		var mapping : InjectionMapping = this._mapping[ mappingID ];
		if ( mapping != null )
		{
			return mapping.provider != null;
		}
		else
		{
			return false;
		}
	}

    public function injectInto( target : Dynamic ) : Void
	{
		var targetType : Class<Dynamic> = Type.getClass( target );
		var classDescription : ClassDescription = this._classDescriptor.getClassDescription( targetType );
		if ( classDescription != null )
		{
			this._applyInjection( target, targetType, classDescription );
		}
	}

    public function destroyInstance( instance : Dynamic ) : Void
	{
		
	}

	//
	public function map( type : Class<Dynamic>, name : String = '' ) : InjectionMapping
	{
		var mappingID : String = Type.getClassName( type ) + '|' + name;
trace("map:" + mappingID );
		if ( this._mapping[ mappingID ] != null )
		{
			return this._mapping[ mappingID ];
		}
		else
		{
			return this._createMapping( type, name, mappingID );
		}
	}

	function _createMapping( type : Class<Dynamic>, name : String, mappingID : String ) : InjectionMapping
	{
		if ( this._processedMapping[ mappingID ] )
		{
			throw new InjectorException( "Mapping named '" + mappingID + "' is already processing @" + Stringifier.stringify( this ) );
		}

		this._processedMapping[ mappingID ] = true;

		var mapping = new InjectionMapping( this, type, name, mappingID );
		this._mapping[ mappingID ] = mapping;
		this._processedMapping.remove( mappingID );

		return mapping;
	}
	
	function _applyInjection( target : Dynamic, targetType : Class<Dynamic>, classDescription : ClassDescription ) : Void
	{
		this._ed.dispatchEvent( new InjectionEvent( InjectionEvent.PRE_CONSTRUCT, this, target, targetType ) );
		
		classDescription.applyInjection( target, this );
		
		/*if ( description.preDestroyMethods != null )
		{
			this._managedObjects.put( target,  target );
		}*/
		
		this._ed.dispatchEvent( new InjectionEvent( InjectionEvent.POST_CONSTRUCT, this, target, targetType ) );
	}
}