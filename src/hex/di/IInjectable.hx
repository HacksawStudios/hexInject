package hex.di;

/**
 * @author Francis Bourre
 */
interface IInjectable 
{
	function applyInjection( target : Dynamic, injector : SpeedInjector ) : Dynamic;
}