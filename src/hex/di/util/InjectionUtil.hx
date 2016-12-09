package hex.di.util;

import haxe.macro.Context;
import haxe.macro.Expr;
import hex.di.Dependency;
import hex.di.IDependencyInjector;
import hex.error.PrivateConstructorException;
import hex.util.MacroUtil;

using haxe.macro.Tools;

/**
 * ...
 * @author Francis Bourre
 */
class InjectionUtil 
{
	/** @private */
    function new()
    {
        throw new PrivateConstructorException( "This class can't be instantiated." );
    }
	
	macro public static function getDependencyInstance<T>( 	injector : ExprOf<IDependencyInjector>, 
															clazz : ExprOf<Dependency<T>>
														) : Expr
	{
		var classReference = InjectionUtil._getStringClassRepresentation( clazz );
		return macro { $injector.getInstanceWithClassName( $v{ classReference } ); };
	}
	
	macro public static function mapDependencyToValue<T>( 	injector : ExprOf<IDependencyInjector>, 
															clazz : ExprOf<Dependency<T>>, 
															value : ExprOf<T>,
															?id : ExprOf<String>
														) : Expr
	{
		var classReference = InjectionUtil._getStringClassRepresentation( clazz );
		return macro { $injector.mapClassNameToValue( $v{ classReference }, $value, $id ); };
	}
	
	macro public static function mapDependencyToType<T>( 	injector : ExprOf<IDependencyInjector>, 
															clazz : ExprOf<Dependency<T>>, 
															type : ExprOf<Dependency<T>>,
															?id : ExprOf<String>
														) : Expr
	{
		var classReference = InjectionUtil._getStringClassRepresentation( clazz );
		var typeReference = InjectionUtil._getClassReference( type );
		return macro { $injector.mapClassNameToType( $v{ classReference }, $typeReference, $id ); };
	}
	
	macro public static function mapDependencyToSingleton<T>( 	injector : ExprOf<IDependencyInjector>, 
																clazz : ExprOf<Dependency<T>>, 
																type : ExprOf<Dependency<T>>,
																?id : ExprOf<String>
															) : Expr
	{
		var classReference = InjectionUtil._getStringClassRepresentation( clazz );
		var typeReference = InjectionUtil._getClassReference( type );
		return macro { $injector.mapClassNameToSingleton( $v{ classReference }, $typeReference, $id ); };
	}
	
	#if macro
	static function _getStringClassRepresentation<T>( clazz : ExprOf<Dependency<T>> ) : String
	{
		switch( clazz.expr )
		{
			case ENew( t, params ):

				switch( t.params[ 0 ] )
				{
					case TPType( t ):
						
						return t.toType().toString().split( ' ' ).join( '' );
					
					case _:
				}
				
			case _:
		}
		
		Context.error( "Invalid dependency", clazz.pos );
		return "";
	}
	
	static function _getClassReference<T>( clazz : ExprOf<Dependency<T>> ) : ExprOf<Class<T>>
	{
		switch( clazz.expr )
		{
			case ENew( t, params ):

				switch( t.params[ 0 ] )
				{
					case TPType( TPath( tp ) ):
						return macro $p { MacroUtil.getPack( MacroUtil.getClassFullQualifiedName( tp ) ) };
						
					case _:
				}
				
			case _:
		}
		
		Context.error( "Invalid dependency", clazz.pos );
		return macro null;
	}
	#end
}