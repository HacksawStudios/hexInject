package hex.di.mock.injectees;

import hex.di.ISpeedInjectorContainer;
import hex.di.mock.types.Clazz;

/**
 * ...
 * @author Francis Bourre
 */
class TwoNamedParametersConstructorInjectee implements ISpeedInjectorContainer
{
	var m_dependency 	: Clazz;
	var m_dependency2 	: String;
	
	@Inject( "namedDependency", "namedDependency2" )
	public function new( dependency : Clazz, dependency2 : String )
	{
		this.m_dependency 	= dependency;
		this.m_dependency2 	= dependency2;
	}
	
	public function getDependency() : Clazz
	{
		return this.m_dependency;
	}
	public function getDependency2() : String
	{
		return this.m_dependency2;
	}
}