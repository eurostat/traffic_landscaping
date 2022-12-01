/*  This file is part of Openrouteservice.
 *
 *  Openrouteservice is free software; you can redistribute it and/or modify it under the terms of the 
 *  GNU Lesser General Public License as published by the Free Software Foundation; either version 2.1 
 *  of the License, or (at your option) any later version.

 *  This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
 *  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
 *  See the GNU Lesser General Public License for more details.

 *  You should have received a copy of the GNU Lesser General Public License along with this library; 
 *  if not, see <https://www.gnu.org/licenses/>.  
 */
package org.heigit.ors.routing.graphhopper.extensions.weighting;

import com.graphhopper.routing.weighting.AbstractAdjustedWeighting;
import com.graphhopper.routing.weighting.Weighting;
import com.graphhopper.util.EdgeIteratorState;

public class AdditionWeighting extends AbstractAdjustedWeighting {
	private Weighting[] weightings;

    public AdditionWeighting(Weighting[] weightings, Weighting superWeighting) {
        super(superWeighting);
        this.weightings = weightings.clone();
    }
    
    @Override
    public double calcWeight(EdgeIteratorState edgeState, boolean reverse, int prevOrNextEdgeId, long edgeEnterTime) {
        double sumOfWeights = 0;
		for (Weighting w:weightings) {
			sumOfWeights += w.calcWeight(edgeState, reverse, prevOrNextEdgeId);
		}
    	return superWeighting.calcWeight(edgeState, reverse, prevOrNextEdgeId, edgeEnterTime) * sumOfWeights;
    }

	@Override
	public String getName() {
		return "addition";
	}

	@Override
	public int hashCode() {
		return ("AddWeighting" + toString()).hashCode();
	}

	@Override
	public boolean equals(Object obj) {
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		final AdditionWeighting other = (AdditionWeighting) obj;
		return toString().equals(other.toString());
	}
}
